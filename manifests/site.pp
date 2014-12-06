require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}


Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

# install nvm, nodejs and some modules
class nvmplusnode {
  require nvm

  exec { "nvm install":
    command => "nvm install 0.10",
    path => "/opt/boxen/bin:/bin"
  }
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # default ruby versions
  ruby::version { '1.9.3': }
  ruby::version { '2.1.2': }

  include nvmplusnode

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  # Adorable-specific Applications
  include flowdock
  include googledrive
  include iterm2::stable
  include screenhero
  # include btsync # Currently does not work; see https://github/boxen/puppet-btsync/issues/2
  include chrome
  include firefox
  include spectacle
  include virtualbox

  # Install 1Password and Chrome helper
  include onepassword
  include onepassword::chrome

  # We want Sublime Text 3
  include sublime_text
  sublime_text::package {'Emmet':
    source => 'sergeche/emmet-sublime'
  }  

  class { 'vagrant': }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }
}
