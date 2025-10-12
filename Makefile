all:
	git add .
	git commit -m "Site Rebuilded at `date +%Y-%m-%d_%H:%M:%S`"
	git push
