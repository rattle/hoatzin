require 'svm'
require 'fast_stemmer'
require 'iconv'

module Hoatzin
  class Classifier

    class ReadOnly < Exception; end

    attr_reader :classifications

    def initialize options = {}

      @metadata_file = options.delete(:metadata) || nil
      @model_file = options.delete(:model) || nil
      @documents = []
      @dictionary = []
      @classifications = []
      @labels = []
      @feature_vectors = []
      @problem = @model = nil
      @cache = 0
      @readonly = false

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

      # Tokenize the text
      tokens = Classifier.tokenize(text)

      # Add tokens to word list
      @dictionary << tokens
      @dictionary.flatten!.uniq!

      # Add to list of documents
      @documents << tokens

      # Add classification to classification list
      @labels << @classifications.index(classification)

      # Compute the feature vectors
      @feature_vectors = @documents.map { |doc| @dictionary.map{|x| doc.include?(x) ? 1 : 0} }
    end

    def classify text
      # Only update the model if we've trained more documents since it was last updated
      if !@readonly && @documents.length > @cache
        return nil if @documents.length == 0
        @cache = @documents.length
        assign_model
      end

      # Tokenize the text
      tokens = Classifier.tokenize(text)

      # Calculate the feature vectors for the text to be classified
      f_vector = @dictionary.map{|x| tokens.include?(x) ? 1 : 0}

      # Classify and return classification
      pred, probs = @model.predict_probability(f_vector)
      @classifications[pred.to_i]
    end

    def save options = {}
      @metadata_file = options[:metadata] if options.key?(:metadata)
      @model_file = options[:model] if options.key?(:model)
      return false unless (@metadata_file && @model_file)
      data = { :dictionary => @dictionary, :classifications => @classifications}
      data.merge!(:documents => @documents,
                  :labels => @labels,
                  :feature_vectors => @feature_vectors,
                  :cache => @cache) if options[:update]
      File.open(@metadata_file, 'w+') { |f| Marshal.dump(data, f) }
      assign_model if @model.nil?
      @model.save(@model_file)
    end

    protected
    def load
      data = {}
      File.open(@metadata_file) { |f| data = Marshal.load(f) }
      @dictionary = data[:dictionary]
      @classifications = data[:classifications]
      if data.key?(:documents)
        @documents = data[:documents]
        @labels = data[:labels]
        @feature_vectors = data[:feature_vectors]
        @cache = data[:cache]
      end
      @readonly = @documents.length > 0 ? false : true
      @model = Model.new(@model_file)
    end

    def assign_model
      @problem = Problem.new(@labels, @feature_vectors)
      @model = Model.new(@problem, @parameters)
    end

    # Adapted from ankusa, to replace with tokenizer gem
    def self.tokenize text
      tokens = []
      # from http://www.jroller.com/obie/tags/unicode
      converter = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
      converter.iconv(text).unpack('U*').select { |cp| cp < 127 }.pack('U*') rescue ""
      text.tr('-', ' ').gsub(/[^\w\s]/," ").split.each do |token|
        tokens << token if (token.length > 3 && !Classifier.stop_words.include?(token))
      end
      tokens
    end

    # ftp://ftp.cs.cornell.edu/pub/smart/english.stop
    def self.stop_words
      %w{
          a a's able about above according accordingly across actually after
          afterwards again against ain't all allow allows almost alone along
          already also although always am among amongst an and another any
          anybody anyhow anyone anything anyway anyways anywhere apart appear
          appreciate appropriate are aren't around as aside ask asking
          associated at available away awfully b be became because become
          becomes becoming been before beforehand behind being believe below
          beside besides best better between beyond both brief but by c
          c'mon c's came can can't cannot cant cause causes certain certainly
          changes clearly co com come comes concerning consequently consider
          considering contain containing contains corresponding could couldn't
          course currently d definitely described despite did didn't different
          do does doesn't doing don't done down downwards during e each edu
          eg eight either else elsewhere enough entirely especially et etc
          even ever every everybody everyone everything everywhere ex exactly
          example except f far few fifth first five followed following follows
          for former formerly forth four from further furthermore g get gets
          getting given gives go goes going gone got gotten greetings h had
          hadn't happens hardly has hasn't have haven't having he he's hello
          help hence her here here's hereafter hereby herein hereupon hers
          herself hi him himself his hither hopefully how howbeit however i
          i'd i'll i'm i've ie if ignored immediate in inasmuch inc indeed
          indicate indicated indicates inner insofar instead into inward is
          isn't it it'd it'll it's its itself j just k keep keeps kept know
          knows known l last lately later latter latterly least less lest let
          let's like liked likely little look looking looks ltd m mainly many
          may maybe me mean meanwhile merely might more moreover most mostly
          much must my myself n name namely nd near nearly necessary need needs
          neither never nevertheless new next nine no nobody non none noone
          nor normally not nothing novel now nowhere o obviously of off often
          oh ok okay old on once one ones only onto or other others otherwise
          ought our ours ourselves out outside over overall own p particular
          particularly per perhaps placed please plus possible presumably
          probably provides q que quite qv r rather rd re really reasonably
          regarding regardless regards relatively respectively right s said
          same saw say saying says second secondly see seeing seem seemed
          seeming seems seen self selves sensible sent serious seriously
          seven several shall she should shouldn't since six so some somebody
          somehow someone something sometime sometimes somewhat somewhere soon
          sorry specified specify specifying still sub such sup sure t t's
          take taken tell tends th than thank thanks thanx that that's thats
          the their theirs them themselves then thence there there's thereafter
          thereby therefore therein theres thereupon these they they'd they'll
          they're they've think third this thorough thoroughly those though
          three through throughout thru thus to together too took toward
          towards tried tries truly try trying twice two u un under
          unfortunately unless unlikely until unto up upon us use used useful
          uses using usually uucp v value various very via viz vs w want wants
          was wasn't way we we'd we'll we're we've welcome well went were weren't
          what what's whatever when whence whenever where where's whereafter
          whereas whereby wherein whereupon wherever whether which while
          whither who who's whoever whole whom whose why will willing wish
          with within without won't wonder would would wouldn't x y yes yet
          you you'd you'll you're you've your yours yourself yourselves
          z zero
        }
    end


  end
end
