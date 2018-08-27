# Class: vision_nginx::config

# Set to $package_version to 'absent' to not install nginx from repositories,
# set to to 'latest' to install the most recent version or pin a version (e.g. '1.12.1-1')

class vision_nginx (

  Hash $vhosts,
  Hash $vhost_defaults,
  String $conf_dir,
  String $package_version    = 'absent',
  String $package_name       = 'nginx-full',
  Optional[String] $x509_key = undef,
  Optional[String] $x509_crt = undef,
  Optional[String] $dhparams = undef,

) {

  class { 'nginx':
    package_ensure       => $package_version,
    package_name         => $package_name,
    manage_repo          => false,
    mail                 => false,
    # purge configuration directories
    server_purge         => true,
    confd_purge          => true,
    conf_dir             => $conf_dir,
    server_tokens        => 'off',
    worker_processes     => 'auto',
    worker_rlimit_nofile => 4096,
  }

  # use non standard configuration directory
  if $conf_dir != '/etc/nginx' {
    file { '/etc/nginx':
      ensure => link,
      target => $conf_dir,
      force  => true,
    }
  }

  # $conf_dir gets created by nginx module
  file { "${conf_dir}/ssl":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0500',
    require => File[$conf_dir],
  }

  if $x509_key != undef {
    file { "${conf_dir}/ssl/private-key.pem":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $x509_key,
      require => File["${conf_dir}/ssl"],
    }
  }

  if $x509_crt != undef {
    file { "${conf_dir}/ssl/cert.pem":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $x509_crt,
      require => File["${conf_dir}/ssl"],
    }
  }

  if $dhparams != undef {
    file { "${conf_dir}/ssl/dhparams.pem":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $dhparams,
      require => File["${conf_dir}/ssl"],
    }
  }

  file { "${conf_dir}/mime.types":
    ensure  => 'present',
    content => template('vision_nginx/mime.types'),
  }

  create_resources('::nginx::resource::server', $vhosts, $vhost_defaults)

}
