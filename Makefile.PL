use v5.26;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Blockchain::Ethereum::Keystore',
    AUTHOR           => q{Reginaldo Costa <refeco@cpan.org>},
    VERSION_FROM     => 'lib/Blockchain/Ethereum/Keystore.pm',
    ABSTRACT_FROM    => 'lib/Blockchain/Ethereum/Keystore.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => 'v5.26',
    META_MERGE       => {
        'meta-spec' => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/refeco/perl-ethereum-keystore.git',
                web  => 'https://github.com/refeco/perl-ethereum-keystore]',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Object::Pad'              => '0.79',
        'Crypt::Digest::Keccak256' => '0.078',
        'Crypt::PK::ECC'           => '0.078',
        'Crypt::PRNG'              => '0.078',
        'Crypt::KeyDerivation'     => '0.078',
        'Crypt::Perl'              => '0.38',
        'Crypt::ScryptKDF'         => '0.010',
        'Net::SSH::Perl'           => '2.14',
        'JSON::MaybeXS'            => '1.004005',
        'File::Slurp'              => '9999.32',
        'Bitcoin::Crypto'          => '1.008',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'Blockchain-Ethereum-Keystore-*'},
);

WriteMakefile(%WriteMakefileArgs);
