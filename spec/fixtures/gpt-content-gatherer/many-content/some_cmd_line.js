// Write a tool to watch command line for the word "foo" and print "bar" when it is found.

var spawn = require('child_process').spawn;

var child = spawn('tail', ['-f', '/dev/stdin']);

child.stdout.on('data', function(data) {
  if (data.toString().indexOf('foo') !== -1) {
    console.log('bar');
  }
}
