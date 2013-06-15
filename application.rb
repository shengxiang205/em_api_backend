#encoding: utf-8
# initialize log
require 'logger'
require 'base64'
require 'zlib'
require 'stringio'

Dir.mkdir('log') unless File.exist?('log')
class ::Logger; alias_method :write, :<<; end
case ENV["RACK_ENV"]
when "production"
  logger = ::Logger.new("log/production.log")
  logger.level = ::Logger::WARN
when "development"
  logger = ::Logger.new(STDOUT)
  logger.level = ::Logger::DEBUG
else
  logger = ::Logger.new("/dev/null")
end

Cache = Dalli::Client.new(['192.168.10.249:11211'], threadsafe: true, failover: true, namespace: 'data_ocean')
Connection = Mongo::MongoReplicaSetClient.new(
  [
    '192.168.10.248:40000',
    '192.168.10.239:40000',
    '192.168.10.246:40000'
  ], :pool_size => 50 )
DB = Connection.db('data_ocean_production_test_env')


class QueryApplication < Sinatra::Base
  module Util
    def self.unpack_raw_args(raw_args)
      zipped_content = Base64.decode64(raw_args)
      zipped_io = StringIO.new(zipped_content)
      JSON.parse(Zlib::GzipReader.new(zipped_io).read, :symbolize_names => true)[:args]
    rescue => e
      []
    end
  end

  register Sinatra::Synchrony

  configure do
    # = Configuration =
    set :run,             false
    set :show_exceptions, development?
    set :raise_errors,    development?
    set :logging,         true
    set :static,          false # your upstream server should deal with those (nginx, Apache)
  end

  configure :production do
  end 

  get '/api/v1/query.*' do
    logger.info "开始访问: #{Time.now.to_f}"
    logger.info params.inspect
    data_lake_stub_name = params[:data_lake_stub]
    command_name        = params[:command]
    args                = params[:args] ||= []

    if params['raw'] == 'true' or params['raw']
      args = Util.unpack_raw_args(params['raw_args'] || '')
    end


    logger.info "Lake的名称: #{data_lake_stub_name}"
    logger.info "查询方法: #{command_name}"
    logger.info "参数: #{args.inspect}"

    start_time = Time.now.tap do |t|
      logger.info "参数解压完毕: #{t.to_f}"
    end

    ids = [
      "connected_droplet_object_ids_#{data_lake_stub_name}",
      "self_droplet_object_ids_#{data_lake_stub_name}"
    ].inject([]) do |ids, cache_key|
      ids += Cache.get(cache_key)
    end.map { |d| BSON::ObjectId(d.to_s) }

    collection = DB['cache_processor_droplets']
    # _id: { '$in' => ids }
    collection.find( _id: { '$in' => ids }, as: args.first).to_a.to_json
  end
end

use Rack::CommonLogger, logger
use Rack::FiberPool, size: 50