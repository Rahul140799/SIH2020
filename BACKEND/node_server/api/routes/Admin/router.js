const express = require('express');
const router = express();
const adminPatient = require('./adminPatient.js');
const adminDoctor  = require('./adminDoctor.js');
const admin = require('./admin');

router.use('/patient',adminPatient);
router.use('/doctor',adminDoctor);
router.use(admin);

module.exports = router;