{exec} = require "child_process"

projectName = "gofer.js"
src = "src/"
ext = ".coffee"

files = [
	"pubsub"
	"jquery-plugins",
	"core",
	"gofer-classes"
]

listOfFiles = ->
	arr = for file in files
		"#{src}#{file}#{ext}"
	return arr.join( " " )

task "watch", "Build project from src/*.coffee to lib/*.js", ->
  exec " coffee -w -j #{projectName} -c -o lib/ " + listOfFiles(), (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task "build", "Build project from src/*.coffee to lib/*.js", ->
  exec " coffee -j #{projectName} -c -o lib/ " + listOfFiles(), (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
