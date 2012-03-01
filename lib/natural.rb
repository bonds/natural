require 'natural/base'
require 'natural/fragment'
require 'natural/expand'

Dir['natural/fragments/*.rb'].each {|a| require a}