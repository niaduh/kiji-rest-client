# (c) Copyright 2013 WibiData, Inc.
#
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kijirest/version"
require 'net/http'
require 'json'
require 'cgi'

module KijiRest
  class Client

    #Error class that wraps exceptions thrown by the server
    class KijiRestClientError < StandardError
      attr_reader :json_error_message
      def initialize(json_error)
        @json_error_message = json_error
      end
    end

    #Constructor for the KijiRest::Client. The only optional argument is the base_uri
    #defining the location of the server.
    def initialize(base_uri="http://localhost:8080")
      @base_uri=base_uri
      @version="v1"
    end

    def instances
      get_json(instances_endpoint)
    end

    def instance(instance_name)
      get_json(instance_endpoint(instance_name))
    end

    def row(instance_name, table_name, rowkey,filters={})
      get_json("#{rows_endpoint(instance_name, table_name)}/#{rowkey}",filters)
    end

    def tables(instance_name)
      get_json(tables_endpoint(instance_name))
    end

    def table(instance_name,table_name)
      get_json(table_endpoint(instance_name, table_name))
    end

    def rows(instance_name,table_name,filters={},&block)
      if !block
        raise "No block given!"
      end

      url_query_params = filters.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
      Net::HTTP.get_response(URI(rows_endpoint(instance_name, table_name) + \
           "?#{url_query_params}")) do |response|
        case response
        when Net::HTTPSuccess then
          remainder_json_line = ""
          response.read_body { |chunk|
            if chunk.size > 0
              #Few possible situations: Not sure what can actually happen let's prepare for all
              #1) chunk is a line that ends with \r\n
              #2) chunk could be multiple lines and also ends with \r\n
              #3) chunk has multiples lines but an incomplete last line.
              remainder_json_line = remainder_json_line + chunk
              if remainder_json_line[-2..-1] == "\r\n"
                json_lines = remainder_json_line.split("\r\n")
                json_lines.each {|line|
                  yield JSON.parse(line)
                }
                remainder_json_line = ""
              else
                json_lines = remainder_json_line.split("\r\n")
                json_lines.slice(0..-2).each {|line|
                  yield JSON.parse(line)
                }
                remainder_json_line = json_lines.last
              end
            end
          }
        else
          raise_exception(response.body)
        end
      end
    end

    private

    def instances_endpoint
      "#{@base_uri}/#{@version}/instances"
    end

    def instance_endpoint(instance_name)
      "#{instances_endpoint}/#{instance_name}"
    end

    def tables_endpoint(instance_name)
      "#{instance_endpoint(instance_name)}/tables"
    end

    def table_endpoint(instance_name, table_name)
      "#{tables_endpoint(instance_name)}/#{table_name}"
    end

    def rows_endpoint(instance_name, table_name)
      "#{table_endpoint(instance_name, table_name)}/rows"
    end

    def raise_exception(response_body)
      begin
        raise KijiRestClientError.new(JSON.parse(response_body))
      rescue
        #If the exception doesn't parse to JSON properly, then return this generic exception
        json_error = "{\"exception\": \"#{response_body}\", \"status\": 500, \"exceptionName\": \"internal error\"}"
        raise KijiRestClientError.new(JSON.parse(json_error))
      end
    end

    def get_json(endpoint,query_params={})
      url_query_params = query_params.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")

      response = Net::HTTP.get_response(URI("#{endpoint}"))
      case response
      when Net::HTTPSuccess then
        JSON.parse(response.body)
      else
        raise_exception(response.body)
      end
    end
  end
end
