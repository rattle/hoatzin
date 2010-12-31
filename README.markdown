# hoatzin

Hoatzin is a text classifier in Ruby that uses SVM for it's classification.

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

The Hoatzin classifier supports saving your trained classifier to the filesystem.  It needs
to store the libsvm model and the associated metadata as two separate files.

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
the :update => true option unless it is definitely required.

## Acknowledgements

See http://www.igvita.com/2008/01/07/support-vector-machines-svm-in-ruby/ for the original inspiration.

## Copyright and License

GPL v3 - See LICENSE.txt for details.
Copyright (c) 2010, Rob Lee
