# Patch BASE_URL in source files

fs = require 'fs'

orig = 'http://localhost:3000'

url = process.argv[process.argv.length-1]

for file in process.argv[2...-1]
    console.log "Update #{file} with #{url}"
    data = fs.readFileSync file, 'utf8'
    unless data
        console.log "Can't read file #{file}"
        process.exit 1
    data = data.replace orig, url
    fs.writeFileSync file, data

console.log "Done." 
