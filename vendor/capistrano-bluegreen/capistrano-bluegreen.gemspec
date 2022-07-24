# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-bluegreen"
  spec.version       = '1.1.3'
  spec.authors       = ["Rafael Biriba"]
  spec.email         = ["biribarj@gmail.com"]
  spec.description   = "Blue-Green deployment solution for Capistrano, using symbolic links between releases."
  spec.summary       = "Blue-Green deployment solution for Capistrano"
  spec.homepage      = "https://github.com/rafaelbiriba/cap_blue_green_deploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject{ |f| f =~ /docs/  }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'capistrano-bundler'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "coveralls"
end
  