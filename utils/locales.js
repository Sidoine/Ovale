const fs = require('fs');

let all = []

fs.readdir("..", (err, files) => {
    for (let file of files) {
        if (!/lua$/.test(file)) continue;
        
        const data = fs.readFileSync(`../${file}`, 'utf8'); 
        let results;
        var maRegex = /\bL\[["'](.*?)["']\]/g;
        while ((results = maRegex.exec(data.toString())) !== null){
            if (all.indexOf(results[1]) < 0)
                all.push(results[1]);
        }
    }

    all.sort();
    for (let a of all){
        console.log(a);
    }
})
