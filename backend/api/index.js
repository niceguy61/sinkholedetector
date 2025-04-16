const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
  'Content-Type': 'application/json'
};

exports.handler = async (event) => {
  try {
    const method = event.httpMethod || event.requestContext.http.method;
    const path = event.path || event.requestContext.http.path;

    // GET /sinkholes - List all sinkholes
    if (method === 'GET' && path.endsWith('/sinkholes')) {
      const params = {
        TableName: process.env.DYNAMODB_TABLE,
        IndexName: 'pubDate-index',
        ScanIndexForward: false // descending order
      };

      const result = await dynamodb.scan(params).promise();
      
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Items)
      };
    }

    // PUT /sinkholes/{id} - Update sinkhole location (admin only)
    if (method === 'PUT' && path.match(/\/sinkholes\/[\w-]+/)) {
      const id = path.split('/').pop();
      const body = JSON.parse(event.body);
      
      const params = {
        TableName: process.env.DYNAMODB_TABLE,
        Key: { id },
        UpdateExpression: 'set #loc = :loc, #lat = :lat, #lng = :lng',
        ExpressionAttributeNames: {
          '#loc': 'location',
          '#lat': 'lat',
          '#lng': 'lng'
        },
        ExpressionAttributeValues: {
          ':loc': body.location,
          ':lat': body.lat,
          ':lng': body.lng
        },
        ReturnValues: 'ALL_NEW'
      };

      const result = await dynamodb.update(params).promise();

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Attributes)
      };
    }

    // Handle OPTIONS for CORS
    if (method === 'OPTIONS') {
      return {
        statusCode: 200,
        headers
      };
    }

    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({ message: 'Not Found' })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        message: 'Internal Server Error',
        error: error.message
      })
    };
  }
};