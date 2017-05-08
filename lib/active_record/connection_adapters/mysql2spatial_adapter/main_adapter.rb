# -----------------------------------------------------------------------------
#
# Mysql2Spatial adapter for ActiveRecord
#
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


# :stopdoc:

module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      class MainAdapter < ConnectionAdapters::Mysql2Adapter

        NATIVE_DATABASE_TYPES = Mysql2Adapter::NATIVE_DATABASE_TYPES.merge(spatial: { name: "geometry", limit: {  type: :point  }})


        def initialize(*args_)
          super
          # Rails 3.2 way of defining the visitor: do so in the constructor
          if defined?(@visitor) && @visitor
            @visitor = ::Arel::Visitors::MySQL2Spatial.new(self)
          end
        end


        def adapter_name
          Mysql2SpatialAdapter::ADAPTER_NAME
        end


        def spatial_column_constructor(name_)
          ::RGeo::ActiveRecord::DEFAULT_SPATIAL_COLUMN_CONSTRUCTORS[name_]
        end


        def native_database_types
          NATIVE_DATABASE_TYPES
        end


        def quote(value_, column_=nil)
          if ::RGeo::Feature::Geometry.check_type(value_)
            "GeomFromWKB(0x#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true, little_endian: true).generate(value_)},#{value_.srid})"
          else
            if column_
              ActiveSupport::Deprecation.warn(<<-MSG.squish)
                Passing a column to `quote` has been deprecated. It is only used
                for type casting, which should be handled elsewhere. See
                https://github.com/rails/arel/commit/6160bfbda1d1781c3b08a33ec4955f170e95be11
                for more information.
              MSG
            end

            super(value_)
          end
        end


        if Gem.loaded_specs['activerecord'].version < Gem::Version.create('5.1.0')
          def type_to_sql(type_, limit_=nil, precision_=nil, scale_=nil, unsigned_=nil)
            if (info_ = spatial_column_constructor(type_.to_sym))
              type_ = limit_[:type] || type_ if limit_.is_a?(::Hash)
              type_ = 'geometry' if type_.to_s == 'spatial'
              type_ = type_.to_s.gsub('_', '').upcase
            end
            super(type_, limit_, precision_, scale_, unsigned_)
          end
        else
          # https://github.com/rails/rails/commit/ae39b1a03d0a859be9d5342592c8936f89fcbacf
          def type_to_sql(type_, limit_:nil, precision_:nil, scale_:nil, unsigned_:nil, **rest_)
            if (info_ = spatial_column_constructor(type_.to_sym))
              type_ = limit_[:type] || type_ if limit_.is_a?(::Hash)
              type_ = 'geometry' if type_.to_s == 'spatial'
              type_ = type_.to_s.gsub('_', '').upcase
            end
            super(type_, rest_.merge({limit:limit_, precision:precision_, scale:scale_, unsigned:unsigned_}))
          end
        end


        def add_index(table_name_, column_name_, options_={})
          if options_[:spatial]
            index_name_ = index_name(table_name_, :column => Array(column_name_))
            if ::Hash === options_
              index_name_ = options_[:name] || index_name_
            end
            execute "CREATE SPATIAL INDEX #{index_name_} ON #{table_name_} (#{Array(column_name_).join(", ")})"
          else
            super
          end
        end


        def columns(table_name)
          table_name = table_name.to_s
          column_definitions(table_name).map do |field|
            type_metadata = fetch_type_metadata(field[:Type], field[:Extra])
            if type_metadata.type == :datetime && field[:Default] == "CURRENT_TIMESTAMP"
              default, default_function = nil, field[:Default]
            elsif type_metadata.type == :spatial
              # binding.pry
            else
              default, default_function = field[:Default], nil
            end

            new_column(@rgeo_factory_settings, field[:Field], default, type_metadata, field[:Null] == "YES", table_name, default_function, field[:Collation], comment: field[:Comment].presence)
          end
        end

        def new_column(*args) #:nodoc:
          SpatialColumn.new(*args)
        end


        def indexes(table_name, name_=nil)
          indexes = []
          current_index = nil
          execute_and_free("SHOW KEYS FROM #{quote_table_name(table_name)}", 'SCHEMA') do |result|
            each_hash(result) do |row|
              if current_index != row[:Key_name]
                next if row[:Key_name] == 'PRIMARY' # skip the primary key
                current_index = row[:Key_name]

                mysql_index_type = row[:Index_type].downcase.to_sym
                index_type  = INDEX_TYPES.include?(mysql_index_type)  ? mysql_index_type : nil
                index_using = INDEX_USINGS.include?(mysql_index_type) ? mysql_index_type : nil
                if row[:Index_type] != 'SPATIAL'
                  indexes << IndexDefinition.new(row[:Table], row[:Key_name], row[:Non_unique].to_i == 0, [], [], nil, nil, index_type, index_using, row[:Index_comment].presence)
                else
                  indexes << ::RGeo::ActiveRecord::SpatialIndexDefinition.new(row[:Table], row[:Key_name], row[:Non_unique] == 0, [], [], row_[:Index_type] == 'SPATIAL')
                end
              end

              indexes.last.columns << row[:Column_name]
              indexes.last.lengths << row[:Sub_part]  unless indexes.last.try(:spatial)
            end
          end
          indexes
        end


        protected

        def initialize_type_map(m)
          super
          register_class_with_limit m, %r(geometry)i, Type::Spatial
          m.alias_type %r(point)i, 'geometry'
          m.alias_type %r(linestring)i, 'geometry'
          m.alias_type %r(polygon)i, 'geometry'

        end


      end
    end
  end
end

# :startdoc:
