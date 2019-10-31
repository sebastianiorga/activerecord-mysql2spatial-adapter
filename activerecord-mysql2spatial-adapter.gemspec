# -*- encoding: utf-8 -*-
# stub: activerecord-mysql2spatial-adapter 0.5.0.nonrelease ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-mysql2spatial-adapter"
  s.version = "0.6.0.nonrelease"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Daniel Azuma","Kazuo Matsunaga"]
  s.date = "2019-10-31"
  s.description = "This is an ActiveRecord connection adapter for MySQL Spatial Extensions. It is based on the stock MySQL2 adapter, but provides built-in support for spatial columns. It uses the RGeo library to represent spatial data in Ruby."
  s.email = "getlasterror@gmail.com"
  s.extra_rdoc_files = ["README.rdoc", "History.rdoc"]
  s.files = ["History.rdoc", "README.rdoc", "Version", "lib/active_record/connection_adapters/mysql2spatial_adapter.rb", "lib/active_record/connection_adapters/mysql2spatial_adapter/arel_tosql.rb", "lib/active_record/connection_adapters/mysql2spatial_adapter/main_adapter.rb", "lib/active_record/connection_adapters/mysql2spatial_adapter/spatial_column.rb", "lib/active_record/connection_adapters/mysql2spatial_adapter/version.rb", "lib/active_record/type/spatial.rb", "test/tc_basic.rb", "test/tc_spatial_queries.rb"]
  s.homepage = "https://github.com/kazuomatz/activerecord-mysql2spatial-adapter"
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0")
  s.rubyforge_project = "virtuoso"
  s.rubygems_version = "2.2.2"
  s.summary = "An ActiveRecord adapter for MySQL Spatial Extensions, based on RGeo and the mysql2 gem."
  s.test_files = ["test/tc_spatial_queries.rb", "test/tc_basic.rb"]

  s.platform = ::Gem::Platform::RUBY
  s.add_dependency('rgeo-activerecord', '~> 6.2')
  s.add_dependency('mysql2', '~> 0.5')
end
