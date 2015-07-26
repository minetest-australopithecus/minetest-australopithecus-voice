doc := doc

all: doc

clean:
	$(RM) -R $(doc)

.PHONY: doc
doc:
	luadoc -d $(doc) mods/voice

