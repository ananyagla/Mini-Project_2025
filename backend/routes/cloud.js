const express = require('express');
const router = express.Router();
const awsService = require('../services/awsService');
const azureService = require('../services/azureService');

router.post('/costs', async (req, res) => {
  const { cloudProvider } = req.body; // 'aws' or 'azure'

  try {
    let costs;
    if (cloudProvider === 'aws') {
      costs = await awsService.fetchCosts(req.body);
    } else if (cloudProvider === 'azure') {
      costs = await azureService.fetchCosts(req.body);
    } else {
      return res.status(400).json({ success: false, message: 'Invalid cloud provider.' });
    }
    res.json({ success: true, costs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
