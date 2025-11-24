all:
	git add .
	git commit -m "Site Rebuilded at `date +%Y-%m-%d_%H:%M:%S`"
	git push

check:
	qutebrowser "http://127.0.0.1:1313"
	hugo server -D
