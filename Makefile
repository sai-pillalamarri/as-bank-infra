ENV ?= dev

.PHONY: up down

up:
	@case "$(ENV)" in dev|prod) ;; *) echo "ENV must be dev or prod"; exit 1 ;; esac
	gh workflow run environment-up.yml -f environment=$(ENV)

down:
	@case "$(ENV)" in dev|prod) ;; *) echo "ENV must be dev or prod"; exit 1 ;; esac
	gh workflow run environment-down.yml -f environment=$(ENV)
