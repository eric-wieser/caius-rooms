lessc static/style.less static/style.css && echo "Compiled" && uglify -s ./static/style.css -o ./static/style.min.css -c