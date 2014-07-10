require 'fileutils'
require 'tempfile'
require 'time'

module Stove
  class Cookbook
    include Logify

    require_relative 'cookbook/metadata'

    #
    # The path to this cookbook on disk.
    #
    # @return [Pathname]
    #
    attr_reader :path

    #
    # The name of the cookbook (must correspond to the name of the
    # cookbook on the community site).
    #
    # @return [String]
    #
    attr_reader :name

    #
    # The version of this cookbook (originally).
    #
    # @return [String]
    #
    attr_reader :version

    #
    # The metadata for this cookbook.
    #
    # @return [Stove::Cookbook::Metadata]
    #
    attr_reader :metadata

    #
    # Set the category for this cookbook
    #
    # @param [String]
    #   the name of the category (values are restricted by the Community Site)
    #
    attr_writer :category

    #
    # The changeset for this cookbook. This is written by the changelog
    # generator and read by various plugins.
    #
    # @return [String, nil]
    #   the changeset for this cookbook
    #
    attr_accessor :changeset

    #
    # Create a new wrapper around the cookbook object.
    #
    # @param [String] path
    #   the relative or absolute path to the cookbook on disk
    #
    def initialize(path)
      @path = File.expand_path(path)
      load_metadata!
    end

    #
    # The category for this cookbook on the community site.
    #
    # @return [String]
    #
    def category
      @category ||= Community.cookbook(name)['category']
    rescue ChefAPI::Error::HTTPError
      log.warn("Cookbook `#{name}' not found on the Chef community site")
      nil
    end

    #
    # The tag version. This is just the current version prefixed with the
    # letter "v".
    #
    # @example Tag version for 1.0.0
    #   cookbook.tag_version #=> "v1.0.0"
    #
    # @return [String]
    #
    def tag_version
      "v#{version}"
    end

    #
    # Deterine if this cookbook version is released on the community site
    #
    # @warn
    #   This is a fairly expensive operation and the result cannot be
    #   reliably cached!
    #
    # @return [Boolean]
    #   true if this cookbook at the current version exists on the community
    #   site, false otherwise
    #
    def released?
      Community.cookbook(name, version)
      true
    rescue ChefAPI::Error::HTTPNotFound
      false
    end

    #
    # So there's this really really crazy bug that the tmp directory could
    # be deleted mid-request...
    #
    # @return [File]
    #
    def tarball
      @tarball ||= Packager.new(self).tarball
    end

    private
      # Load the metadata and set the @metadata instance variable.
      #
      # @raise [ArgumentError]
      #   if there is no metadata.rb
      #
      # @return [String]
      #   the path to the metadata file
      def load_metadata!
        metadata_path = File.join(path, 'metadata.rb')

        @metadata = Stove::Cookbook::Metadata.from_file(metadata_path)
        @name     = @metadata.name
        @version  = @metadata.version

        metadata_path
      end
      alias_method :reload_metadata!, :load_metadata!
  end
end
