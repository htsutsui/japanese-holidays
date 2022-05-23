files=jp_holidays.yaml jp_holidays.json jp_holidays.csv
all: $(files)
jp_holidays.json: %.json: %.yaml
jp_holidays.csv: %.csv: %.yaml
jp_holidays.yaml: generate.rb
	./generate.rb

clean:
	rm -f *-events.yaml $(files) *~ .*~
