APP ?= registration
REVISION ?= 1
REPO = yetacp/sk-apps

.PHONY: app-check app-release catalog-release app-publish catalog-publish

app-check:
	rtk python3 tools/release_app.py check

app-release: app-check
	rtk make -C ../startk current-app-package APP=$(APP) APP_OUT=../sk-apps/dist
	rtk python3 tools/release_app.py prepare $(APP)

catalog-release: app-check
	rtk python3 tools/release_app.py catalog $(REVISION)

app-publish: app-release
	rtk gh release create $(shell rtk python3 tools/release_app.py tag $(APP)) dist/$(shell rtk python3 tools/release_app.py tag $(APP)).stkp --repo $(REPO) --latest=false --notes "StartK app $(APP)"

catalog-publish: catalog-release
	rtk gh release create catalog-v$(REVISION) dist/catalog-v$(REVISION)/catalog.json dist/catalog-v$(REVISION)/catalog.json.sig --repo $(REPO) --latest --notes "Signed StartK app catalog revision $(REVISION)"
