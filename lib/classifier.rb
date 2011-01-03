module Hoatzin
  class Classifier

    class ReadOnly < Exception; end
    class InvalidFormat < Exception; end

    FORMAT_VERSION = 2

    attr_reader :classifications

    def initialize options = {}

      @documents = []
      @classifications = []
      @labels = []

      @problem = @model = nil
      @cache = 0
      @readonly = false

      @metadata_file = options.delete(:metadata) || nil
      @model_file = options.delete(:model) || nil

      @builder = VectorSpace::Builder.new(:parser => Hoatzin::Parser.new)

      # If we have model and metadata files then load them
      load if @metadata_file && @model_file


      # Define kernel parameters for libsvm
      @parameters = Parameter.new(:C => 100,
                                  :degree => 1,
                                  :coef0 => 0,
                                  :eps => 0.001)

    end

    def train classification, text
      # Only allow retraining if we have all the required data
      raise ReadOnly if @readonly

      # Add the classification if we haven't seen it before
      @classifications << classification unless @classifications.include?(classification)

      # Add to document corpus
      @documents << text

      # Add classification to classification list
      @labels << @classifications.index(classification)
      
    end

    def classify text

      # See if we need to calculate the feature vectors
      sync

      # Calculate the feature vectors for the text to be classified
      f_vector = @builder.build_query_vector(text)

      # Classify and return classification
      pred, probs = @model.predict_probability(f_vector)
      @classifications[pred.to_i]
    end

    def sync
      # Only update the model if we've trained more documents since it was last updated
      if !@readonly && @documents.length > @cache
        return nil if @documents.length == 0
        @cache = @documents.length
        assign_model
      end
    end

    def save options = {}
      @metadata_file = options[:metadata] if options.key?(:metadata)
      @model_file = options[:model] if options.key?(:model)
      return false unless (@metadata_file && @model_file)
      
      # TODO: Add a version identifier
      data = { :classifications => @classifications,
               :version => FORMAT_VERSION,
               :dictionary => @builder.vector_keyword_index,
               :readonly => true }
      data.merge!(:documents => @documents,
                  :cache => @cache,
                  :readonly => false) if options[:update]
      File.open(@metadata_file, 'w+') { |f| Marshal.dump(data, f) }
      assign_model if @model.nil?
      @model.save(@model_file)
    end

    protected
    def load
      data = {}
      File.open(@metadata_file) { |f| data = Marshal.load(f) }
      raise InvalidFormat if !data.key?(:version) || data[:version] != FORMAT_VERSION
      @classifications = data[:classifications]
      @readonly = data[:readonly]
      @builder.vector_keyword_index = data[:dictionary]
      unless @readonly
        @documents = data[:documents]
        @cache = data[:cache]
      end
      @model = Model.new(@model_file)
    end

    def assign_model
      vector_space_model = @builder.build_document_matrix(@documents)
      @problem = Problem.new(@labels, vector_space_model.matrix)
      @model = Model.new(@problem, @parameters)
    end

  end
end
