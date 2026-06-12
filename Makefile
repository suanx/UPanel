.PHONY: build build-cli build-all clean install

# 版本号
VERSION=v0.1.6

# 编译主程序
build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X main.Version=${VERSION}" -o bin/upanel cmd/upanel/main.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/up cmd/upanel/cli/main.go

# 编译所有平台
build-all:
	# Linux amd64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -X main.Version=${VERSION}" -o release/linux/upanel cmd/upanel/main.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o release/linux/up cmd/upanel/cli/main.go
	# Linux arm64
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="-s -w -X main.Version=${VERSION}" -o release/linux-arm64/upanel cmd/upanel/main.go
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o release/linux-arm64/up cmd/upanel/cli/main.go
	# macOS amd64
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w -X main.Version=${VERSION}" -o release/darwin/upanel cmd/upanel/main.go
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o release/darwin/up cmd/upanel/cli/main.go
	# macOS arm64 (M1/M2)
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w -X main.Version=${VERSION}" -o release/darwin-arm64/upanel cmd/upanel/main.go
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o release/darwin-arm64/up cmd/upanel/cli/main.go

# 清理
clean:
	rm -rf bin/ release/

# 安装到本地
install: build
	cp bin/upanel /usr/local/bin/
	cp bin/up /usr/local/bin/
