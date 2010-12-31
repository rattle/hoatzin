require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'hoatzin'

class Test::Unit::TestCase

  TRAINING_LABELS = [1, 1, 0, 1, 1, 0, 0]
  TRAINING_DOCS = [
            'FREE NATIONAL TREASURE',
            'FREE TV for EVERY visitor',
            'Peter and Stewie are hilarious',
            'AS SEEN ON NATIONAL TV',
            'FREE drugs',
            'New episode rocks, Peter and Stewie are hilarious',
            'Peter is my fav!'
            # ...
            ]

  TESTING_LABELS = [1, 0, 0]
  TESTING_DOCS = [
            'FREE lotterry for the NATIONAL TREASURE !!!',
            'Stewie is hilarious',
            'Poor Peter ... hilarious',
            # ...
          ]

  READONLY_METADATA_FILE = File.join(File.dirname(__FILE__), 'models', 'readonly-test', 'model')
  READONLY_MODEL_FILE = File.join(File.dirname(__FILE__), 'models', 'readonly-test', 'metadata')
  METADATA_FILE = File.join(File.dirname(__FILE__), 'models', 'test', 'model')
  MODEL_FILE = File.join(File.dirname(__FILE__), 'models', 'test', 'metadata')
end
