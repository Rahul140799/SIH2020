const express = require('express');
const swaggerUi = require('swagger-ui-express');
const swaggerJSDoc = require('swagger-jsdoc');
const jwt = require('jsonwebtoken');
const {  deploy } = require('./api/routes/Blockchain/connection/deploy.js');
const { auth } = require('./api/middleware/auth.js');
const router = require('./api/routes/router.js');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
var cors = require('cors');
const logger = require('./config/logger')(module);


// const ioserver = require('http').createServer();

// const io = require('socket.io')(ioserver);

// io.on('connect',socket => {
//     console.log('connected : ',socket);
//     socket.emit('welcome',"welcome to the server");
//     socket.on('completedjson',(dataRes) =>{
//         console.log("got completed json",dataRes);
//         io.emit('completedjson',dataRes);
//     });
// });

// ioserver.listen(3001,()=>{console.log("CONNECTION PORT 3001")});
  

// const conn = mongoose.createConnection("mongodb://db:27017/scribeplus", {
//     useNewUrlParser: true,
//     useUnifiedTopology: true
//   });
// let gfs;
mongoose.connect('mongodb://db:27017/scribeplus',
{
        useNewUrlParser: true,
        useUnifiedTopology: true
});


const app = express();
const PORT = process.env.PORT ||3000 ;
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000 }));
app.use(cors());
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Expose-Headers","auth-token")
    res.header("Access-Control-Allow-Headers","Origin, X-Requested-With, Content-Type, Accept, Authorization");

    if (req.method == 'OPTIONS') {
        res.header('Access-Control-Allow-Methods', 'PUT, POST, PATCH, DELETE, GET');
        return res.status(200).json({});
    }
    next();
});

const swaggerOptions = {
    swaggerDefinition : {
        info:{
            version:"v1",
            title:'Scribe Plus API DOC',
            description:'This is a sih project',
            contact:{
                name:"Jay Vishaal J"
            },
        },
    },
    apis:["./api/**/*.js"]
}

const swaggerDocs = swaggerJSDoc(swaggerOptions);
app.use('/api-doc',swaggerUi.serve,swaggerUi.setup(swaggerDocs,{explorer:false,customSiteTitle:"Scribe + Api",customCss:'.swagger-ui .topbar {display:none}'}));
app.use(router);


var server = app.listen(PORT,'0.0.0.0',async ()=> {
    const address = await deploy();
    console.log("ADDRESS : ",address);
    console.log(`SERVER  ON ${PORT}`);
    var host = server.address().address;
    console.log('HOST : ',host);
    logger.log('info',`server is up and running on port ${PORT}`);
    logger.log('info',`contract is deployed to the Address ${address}`);
    // conn.once("open", () => {
    //     // init stream
    //     console.log("CONNECTION OPEN");
    //     gfs = new mongoose.mongo.GridFSBucket(conn.db, {
    //       bucketName: "uploads"
    //     });
    //   });
      
});