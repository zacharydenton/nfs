module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    coffee:
      app:
        options:
          join: true
        files:
          'www/js/app.js': 'src/**/*.coffee'
    less:
      app:
        options:
          compress: true
        files:
          'www/css/app.css': 'src/less/app.less'
    watch:
      app:
        files: ['src/**/*.coffee', 'src/**/*.less', 'src/**/*.html']
        tasks: ['coffee', 'less', 'jst', 'uglify', 'cssmin']
    connect:
      server:
        options:
          port: 9000
          base: 'www'
          hostname: '*'

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'

  # Default task.
  grunt.registerTask 'default', ['connect', 'watch']
