const express = require('express');
const router = express();
const crud = require('./patient_CRUD.js');
const prescription = require('./patient_prescription');

router.use('/prescription',prescription);
router.use(crud);

module.exports = router;