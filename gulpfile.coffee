gulp = require 'gulp'

merge = require 'gulp-merge'

del = require 'del'
concat = require 'gulp-concat'
rename = require 'gulp-rename'
size = require 'gulp-size'

sass = require 'gulp-sass'
coffee = require 'gulp-coffee'
minify = require 'gulp-minify-css'
uglify = require 'gulp-uglify'


gulp.task 'default', ->
    del ['source/**'], ->
        gulp.src 'source/**'
            .pipe size title: 'all', showFiles: true
            .pipe size title: 'all_gzip', gzip: true, showFiles: true
            
        gulp.src 'views/*.ejs'
            .pipe size title: 'views', showFiles: true
            .pipe size title: 'views_gzip', gzip: true, showFiles: true
            
        merge(
            gulp.src 'source/sass/*.sass'
                .pipe concat 'style.sass'
                .pipe sass()

            gulp.src 'source/css/*.css'
        )
            .pipe size title: 'css', showFiles: true
            .pipe concat 'style.css'
            .pipe minify()
            .pipe size title: 'css_min', gzip: true, showFiles: true
            .pipe gulp.dest 'static'
        
        merge(
            gulp.src 'source/coffee/*.coffee'
                .pipe concat 'script.coffee'
                .pipe coffee()

            gulp.src 'source/js/*.js'
        )
            .pipe size title: 'js', showFiles: true
            .pipe concat 'script.js'
            #.pipe uglify mangle: except: 'm,Parse'
            .pipe size title: 'js_min', gzip: true, showFiles: true
            .pipe gulp.dest 'static'