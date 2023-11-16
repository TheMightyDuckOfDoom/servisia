all: out/serivisa.v

init:
	git submodule update --init

update:
	git submodule update

out/serivisa.v: rtl/servisia.v
	mkdir -p out
	bender sources -f > out/sources.json
	morty -f out/sources.json --top servisia > out/servisia.v

clean:
	rm -r out