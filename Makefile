.PHONY: release lint audit test test-javascript clean

release:
	ruby usr/bin/release.rb

lint:
	bundle exec rubocop
	bundle exec rbs validate

audit:
	bundle exec bundler-audit check

test-javascript:
	bundle exec polyrun -c polyrun.javascript.yml run-shards --workers 5 -- node --test

test: lint test-javascript
	bundle exec polyrun parallel-rspec --workers 5 --merge-failures

clean:
	rm -rf coverage .pray/cache tmp
	rm -f spec/examples.txt *.gem
