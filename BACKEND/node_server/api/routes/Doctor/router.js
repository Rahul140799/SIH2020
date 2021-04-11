const express = require('express');
const router = express();
const upload = require("./doctor_upload.js");
const crud   = require("./doctor_CRUD.js");
const appointment = require('./doctor_appointment');
const followup = require('./doctor_telegram_follow_up');
const wallet = require('./doctorWallet');

router.use('/upload', upload);
router.use('/appointment', appointment);
router.use('/followup',followup);
router.use('/wallet',wallet);
router.use(crud);


module.exports = router;