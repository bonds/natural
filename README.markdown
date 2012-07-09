# Natural

Natural provides a framework for answering 'naturally' worded questions like 'how many books did I buy last month' or 'list my Facebook friends'.

## Installation

	$ gem install natural

## Example

	$ require 'natural'
	$ Natural.new('how many days of the week start with the letter T').answer
	=> 2
	
## Example Log

	[n][perf] matching took 1.6 seconds
	[n][perf] scoring took 0.1 seconds
	[n]
	[n][scor] 45 how many | days of the week | start with the letter t
	[n][scor] 41 days of the week | start with the letter t
	[n][scor] 31 how many | days | week | start with the letter t
	[n][scor] 30 how many | days | start with the letter t
	[n][scor] 30 how many | week | start with the letter t
	[n][scor] 29 how many | start with the letter t
	[n][scor] 27 days | week | start with the letter t
	[n][scor] 26 week | start with the letter t
	[n][scor] 26 days | start with the letter t
	[n][scor] 25 start with the letter t
	[n][scor] 20 how many | days of the week
	[n][scor] 19 how many | days of the week | commence
	[n][scor] 19 how many | days of the week | begin
	[n][scor] 16 days of the week
	[n][scor] 15 days of the week | begin
	[n][scor] 15 days of the week | commence
	[n][scor] 06 how many | days | week
	[n][scor] 05 how many | week
	[n][scor] 05 how many | days | week | begin
	[n][scor] 05 how many | days
	[n][scor] 05 how many | days | week | commence
	[n][scor] 04 how many | week | commence
	[n][scor] 04 how many | days | commence
	[n][scor] 04 how many
	[n][scor] 04 how many | days | begin
	[n][scor] 04 how many | week | begin
	[n][scor] 03 how many | begin
	[n][scor] 03 how many | commence
	[n][scor] 02 days | week
	[n][scor] 01 days
	[n][scor] 01 week
	[n][scor] 01 days | week | begin
	[n][scor] 01 days | week | commence
	[n][scor] 00 week | commence
	[n][scor] 00 days | begin
	[n][scor] 00 week | begin
	[n][scor] 00 days | commence
	[n][scor] -1 commence
	[n][scor] -1 begin
	[n]
	[n][tree] * how many days of the week start with the letter T fragment (0..10)
	[n][tree] |---> how many count (0..1)
	[n][tree] |---> days of the week day_names (2..5)
	[n][tree] +---+ start with the letter t starts_with_letter (6..10)
	[n][tree]     |---> start with the letter fragment (6..9)
	[n][tree]     +---> t fragment (10)
	[n]
	[n][orig] how many days of the week start with the letter T
	[n][used] how many days of the week start with the letter t

## Creating Your Vocabulary

* create a class that inherits from Natural::Fragment
* override class method 'find' to specify which phrases it should match
- return a hash of all matches found so far, keys are the match class, values are the matches for that class
* optional: override instance method 'data' to specify which data a match adds to the answer
* optional: override instance method 'filters' to specify which method to call on each data set in the answer to filter out results
* optional: override instance method 'aggregators' to specify which method to call on each data set to aggregate results
* optional: override instance method 'score' to specify the relative value of a match

This is a bit easier to understand by looking at an example, take a gander at: lib/natural/fragments/example.rb

### Simple Fragments

	class Letter < Natural::Fragment
		def self.find(options)
			super options.merge(:looking_for => ('a'..'z').to_a)
		end
	end

### Compound Fragments

	class StartsWithLetter < Natural::Fragment
		def self.find(options)
			super options.merge(:looking_for => {:and => ['start with the letter', Letter]})
		end
	end

### Alternative Spellings, Synonyms, and Expansions

	Natural.new('how many days of the wek beginn with the letter T').answer

	[n][tree] * how many days of the wek beginn with the letter T fragment (0..10)
	[n][tree] |---> how many count (0..1)
	[n][tree] |---+ days of the week day_names (2..5)
	[n][tree] |   |---> days of the fragment (2..4)
	[n][tree]     +---+ week spelling (5)
	[n][tree]         +---> wek fragment (5)
	[n][tree] +---+ start with the letter t starts_with_letter (6..10)
	[n][tree]     |---+ start with the letter fragment (6..9)
	[n][tree] |       |---+ start synonym (6)
	[n][tree] |           +---+ begin spelling (6)
	[n][tree]                 +---> beginn fragment (6)
	[n][tree] |       +---> with the letter fragment (7..9)
	[n][tree]     +---> t fragment (10)
	[n]
	[n][orig] how many days of the wek begin with the letter T
	[n][used] how many days of the week start with the letter t

	Natural.new('movies').answer

	[n][tree] * movies fragment (0)
	[n][tree] +---+ blu-rays blu_ray (0)
	[n][tree]     +---+ blu-rays expansion (0)
	[n][tree]         +---> movies fragment (0)

### Plurals and Inflectors

Everything is singularized and downcased before being matched. `lib/natural/inflections.rb` can be used to customize the singularization behavior.

### Scoring

## Generating the Answer

### Data

### Filters

### Aggregators

### Putting Them Together

use the built in answer method or DIY: navigate the tree and assemble data, filters, and aggregators any way you want

## Performance

Natural has not (yet) been optimized for cpu or memory usage. Natural works best with short questions and a small vocabulary.

### Matching

You can match according to the highest scoring combination of words (slower, defalt), or you can match in the order of the passed in fragment_classes, ignoring any words that are already matched (faster).

	Natural.new('how many days of the week start with the letter T', :matching => :first_match, :fragment_classes => [StartsWithLetter, DayNames, Count]).answer

## Contributing to Natural
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Scott Bonds. See LICENSE.txt for
further details.
