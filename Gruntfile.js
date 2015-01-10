/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Task configuration.
    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        unused: true,
        boss: true,
        eqnull: true,
        browser: true,
        mocha: true,
        globals: {
          "__dirname": false,
          console: false,
          require: false
        }
      },
      gruntfile: {
        src: 'Gruntfile.js'
      },
      lib_test: {
        src: ['lib/**/*.js', 'test/**/*.js']
      }
    },
    livescript: {
      src: {
        files: {
          //'*.js': '*.ls'
          'js/english.js': 'src/english.ls',
          'test-js/english-test.js': 'test/english-test.ls'
          //'path/to/result.js': 'path/to/source.ls', // 1:1 compile
         //'path/to/another.js': ['path/to/sources/*.ls', 'path/to/more/*.ls'] // compile and concat into single file
        }
      }
    },
    mochaTest: {
      test: {
        options: {
          // captureFile: 'results.txt', // Optionally capture the reporter output to a file
          clearRequireCache: false, // Optionally clear the require cache before running tests (defaults to false)
          harmony: true,
          quiet: false, // Optionally suppress output to standard out (defaults to false)
          reporter: 'spec'
        },
        src: ['test-js/**/*.js']
      }
    },
    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      lib_test: {
        files: '<%= jshint.lib_test.src %>',
        tasks: ['jshint:lib_test']
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-livescript');

  // Default task.
  grunt.registerTask('default', ['livescript', 'jshint', 'mochaTest']);

};
