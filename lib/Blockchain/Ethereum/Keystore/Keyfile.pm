use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::Keystore::Keyfile 0.005;
class Blockchain::Ethereum::Keystore::Keyfile;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Keystore::Keyfile - Ethereum Keyfile abstraction

=head1 SYNOPSIS

Ethereum keyfile abstraction

Currently only supports read and write for keyfile v3

=cut

use Carp;
use File::Slurp;
use JSON::MaybeXS qw(decode_json encode_json);
use Crypt::PRNG;
use Net::SSH::Perl::Cipher;

use Blockchain::Ethereum::Keystore::Key;
use Blockchain::Ethereum::Keystore::Keyfile::KDF;

field $cipher :reader :writer;
field $ciphertext :reader :writer;
field $mac :reader :writer;
field $version :reader :writer;
field $iv :reader :writer;
field $kdf :reader :writer;
field $id :reader :writer;
field $private_key :reader :writer;

field $_json :reader(_json) = JSON::MaybeXS->new(utf8 => 1);

=head2 import_file

Import a v3 keyfile

Usage:

    import_file($file_path) -> $self

=over 4

=item * C<file_path> - string path for the keyfile

=back

self

=cut

method import_file ($file_path, $password) {

    my $content = read_file($file_path);
    my $decoded = $self->_json->decode(lc $content);

    return $self->_from_object($decoded, $password);
}

method _from_object ($object, $password) {

    my $version = $object->{version};

    croak 'Could not determine the version' unless $version >= 3;

    return $self->_from_v3($object, $password);
}

method _from_v3 ($object, $password) {

    my $crypto = $object->{crypto};

    $self->set_cipher('AES128_CTR');
    $self->set_ciphertext($crypto->{ciphertext});
    $self->set_mac($crypto->{mac});
    $self->set_version(3);
    $self->set_iv($crypto->{cipherparams}->{iv});

    my $header = $crypto->{kdfparams};

    $self->set_kdf(
        Blockchain::Ethereum::Keystore::Keyfile::KDF->new(
            algorithm => $crypto->{kdf},     #
            dklen     => $header->{dklen},
            n         => $header->{n},
            p         => $header->{p},
            r         => $header->{r},
            c         => $header->{c},
            prf       => $header->{prf},
            salt      => $header->{salt}));

    $self->set_private_key($self->_private_key($password));

    return $self;
}

=head2 change_password

Change the imported keyfile password

Usage:

    change_password($old_password, $new_password) -> $self

=over 4

=item * C<old_password> - Current password for the keyfile

=item * C<new_password> - New password to be set

=back

self

=cut

method change_password ($old_password, $new_password) {

    return $self->import_key($self->_private_key($old_password), $new_password);
}

method _private_key ($password) {

    return $self->private_key if $self->private_key;

    my $cipher = Net::SSH::Perl::Cipher->new(
        $self->cipher,    #
        $self->kdf->decode($password),
        pack("H*", $self->iv));

    my $key = $cipher->decrypt(pack("H*", $self->ciphertext));

    return Blockchain::Ethereum::Keystore::Key->new(private_key => $key);
}

=head2 import_key

Import a L<Blockchain::Ethereum::keystore::Key>

Usage:

    import_key($keyfile) -> $self

=over 4

=item * C<keyfile> - L<Blockchain::Ethereum::Keystore::Key>

=back

self

=cut

method import_key ($key, $password) {

    # use the internal method here otherwise would not be availble to get the kdf params
    # salt if give will be the same as the response, if not will be auto generated by the library
    my ($derived_key, $salt, $N, $r, $p);
    ($derived_key, $salt, $N, $r, $p) = Crypt::ScryptKDF::_scrypt_extra($password);
    $self->kdf->set_algorithm("scrypt");
    $self->kdf->set_dklen(length $derived_key);
    $self->kdf->set_n($N);
    $self->kdf->set_p($p);
    $self->kdf->set_r($r);
    $self->kdf->set_salt(unpack "H*", $salt);

    my $iv = Crypt::PRNG::random_bytes(16);
    $self->set_iv(unpack "H*", $iv);

    my $cipher = Net::SSH::Perl::Cipher->new(
        "AES128_CTR",    #
        $derived_key,
        $iv
    );

    my $encrypted = $cipher->encrypt($key->export);
    $self->set_ciphertext(unpack "H*", $encrypted);

    $self->set_private_key($key);

    return $self;
}

method _write_to_object {

    croak "KDF algorithm and parameters are not set" unless $self->kdf;

    my $file = {
        "crypto" => {
            "cipher"       => 'aes-128-ctr',
            "cipherparams" => {"iv" => $self->iv},
            "ciphertext"   => $self->ciphertext,
            "kdf"          => $self->kdf->algorithm,
            "kdfparams"    => {
                "dklen" => $self->kdf->dklen,
                "n"     => $self->kdf->n,
                "p"     => $self->kdf->p,
                "r"     => $self->kdf->r,
                "salt"  => $self->kdf->salt
            },
            "mac" => $self->mac
        },
        "id"      => $self->id,
        "version" => 3
    };

    return $file;
}

=head2 write_to_file

Write the imported keyfile/private_key to a keyfile in the file system

Usage:

    write_to_file($file_path) -> $self

=over 4

=item * C<file_path> - file path to save the data

=back

returns 1 upon successfully writing the file or undef if it encountered an error

=cut

method write_to_file ($file_path) {

    return write_file($file_path, $self->_json->canonical(1)->pretty->encode($self->_write_to_object));
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-keystore>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
