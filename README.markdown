# hoatzin

Hoatzin is a text classifier in Ruby that uses libsvm for it's classification.

## Installation

gem install hoatzin

## Usage

    # Create a hoatzin classifier
    c = Hoatzin::Classifier.new()

    # Train the classifier with a classification and some text
    c.train(:positive, "Thats nice")

    # This will return the most likely classification (:positive)
    c.classify("Thats nice")

## Storage

The Hoatzin classifier supports saving your trained classifier to the filesystem.  It stores
the generated libsvm model and the required metadata as two separate files.

    # Load a previously trained classifier
    c = Hoatzin::Classifier.new(:metadata => '/path/to/file', :model => '/path/to/file')

    # Save an existing trained classifier, without training data
    # The #train method will raise an exception if called when the classifier is reloaded
    c.save(:metadata => '/path/to/file', :model => '/path/to/file')

    # Save an existing trained classifier, with training data
    # The #train method can continue to be called when the classifier is reloaded
    c.save(:metadata => '/path/to/file', :model => '/path/to/file', :update => true)

The classifier can continue to be trained if the model is saved with the :update => true option,
however the files stored on the filesystem will be much larger as they will contain copies
of all the documents used during training the classifier.  It is generally advised to save without
the :update => true option unless it is required.

## Training

The #train method doesn't calculate all the required information for classification
(in particular the feature vectors) due to the time they take to recompute for each new
token generated when adding a document for training. This means that there can be a delay
when calling the #classify method for the first time whilst all the required information
is prepared. This preparation step can be explicitly called using the #sync method.  This
method is transparently called by the #classify method when required.  Sample usage of the #sync
method is shown below:

    # Create a hoatzin classifier
    c = Hoatzin::Classifier.new()

    # Add the training data to the classifier
    corpus.each do |doc|
      c.train(doc[:classification], doc[:text])
    end

    # Force the calculation of the feature vectors and
    # preparation of the SVM model.  This can take some
    # time if the corpus is large
    c.sync

    # Save the model and associated meta-data so we don't have to
    # call sync again and wait for the feature vectors to be computed
    c.save(:metadata => '/path/to/metadata', :model => '/path/to/model')

    # Now call classify
    c.classify("Spectacular show")

The saved model and metadata can be loaded again for classification, avoiding the
need to recompute the feature vectors.

## Acknowledgements

See http://www.igvita.com/2008/01/07/support-vector-machines-svm-in-ruby/ for the original inspiration.
The Vector Space Model implementation is adapted from https://github.com/josephwilk/rsemantic

## Copyright and License

GPL v3 - See LICENSE.txt for details.
Copyright (c) 2010, Rob Lee
