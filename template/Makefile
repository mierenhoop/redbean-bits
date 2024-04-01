APPNAME=app
REMOTE=myvps
PORT=80

DB_FILE=build/$(APPNAME).db
APP=build/$(APPNAME).com
FILES=.init.lua

.PHONY: $(DB_FILE) test stop upload deploy run-remote clean

all: $(APP)

$(APP): $(FILES)
	./build/redbean.com -ie 'assert(Barf("$(APP)", assert(Slurp"./build/redbean.com")))'
	./build/redbean.com -ie 'assert(unix.chmod("$(APP)", 0755))'
	./build/zip.com -d $(APP) redbean.png favicon.ico help.txt
	./build/zip.com -r $(APP) $(FILES)
	./build/sqlite3.com ':memory:' 'create virtual table temp.zip using zipfile("$(APP)"); update temp.zip set mode = null'

$(DB_FILE):
	./build/redbean.com -ie 'unix.rmrf"$(DB_FILE)"'
	./build/sqlite3.com $(DB_FILE) '.read schema.sql'

test: $(APP) $(DB_FILE)
	./$(APP) -F ./test.lua

stop:
	ssh $(REMOTE) pkill -F /var/opt/$(APPNAME).pid || true

upload: stop $(APP) $(DB_FILE)
	scp $(APP) $(REMOTE):/opt/$(APPNAME).com
	scp $(DB_FILE) $(REMOTE):/var/opt/$(APPNAME).db

deploy: upload
	ssh -t $(REMOTE) /opt/$(APPNAME).com -l 0.0.0.0 -p $(PORT) -d -P /var/opt/$(APPNAME).pid -L /var/opt/$(APPNAME).log

run-remote: upload
	ssh -t $(REMOTE) /opt/$(APPNAME).com -l 0.0.0.0 -p $(PORT)

clean:
	./build/redbean.com -ie 'for _,f in ipairs{"$(DB_FILE)","$(APP)"} do unix.rmrf(f) end'
