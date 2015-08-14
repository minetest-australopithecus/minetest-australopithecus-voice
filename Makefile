doc := doc

all: doc

clean:
	$(RM) -R $(doc)

.PHONY: doc
doc:
	ldoc --dir=$(doc) mods/voice

