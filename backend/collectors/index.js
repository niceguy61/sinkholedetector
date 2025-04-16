const axios = require('axios');
const xml2js = require('xml2js');
const { v4: uuidv4 } = require('uuid');
const AWS = require('aws-sdk');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const KEYWORDS = ['싱크홀', '도로 꺼짐', '지반 침하'];

async function parseXml(xml) {
  return new Promise((resolve, reject) => {
    xml2js.parseString(xml, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
  });
}

async function sendSlackNotification(webhook, message) {
  try {
    await axios.post(webhook, {
      text: message
    });
  } catch (error) {
    console.error('Slack notification failed:', error);
  }
}

async function saveToDynamoDB(item) {
  const params = {
    TableName: process.env.DYNAMODB_TABLE,
    Item: item
  };

  await dynamodb.put(params).promise();
}

function containsKeywords(text) {
  return KEYWORDS.some(keyword => text.includes(keyword));
}

exports.handler = async (event) => {
  try {
    // Fetch RSS feed
    const response = await axios.get(process.env.RSS_FEED_URL);
    const feed = await parseXml(response.data);
    
    const items = feed.rss.channel[0].item;
    const relevantNews = items.filter(item => {
      const title = item.title[0];
      const description = item.description[0];
      return containsKeywords(title) || containsKeywords(description);
    });

    // Process each relevant news item
    for (const news of relevantNews) {
      const item = {
        id: uuidv4(),
        title: news.title[0],
        link: news.link[0],
        guid: news.guid ? news.guid[0]._ || news.guid[0] : news.link[0],
        pubDate: new Date(news.pubDate[0]).toISOString(),
        creator: news['dc:creator'] ? news['dc:creator'][0] : null,
        summary: news.description[0],
        mediaContent: news['media:content'] ? {
          url: news['media:content'][0].$.url,
          type: news['media:content'][0].$.type
        } : null,
        location: null,
        lat: null,
        lng: null,
        notified: false
      };

      // Save to DynamoDB
      await saveToDynamoDB(item);

      // Send Slack notification
      const message = `🚨 새로운 싱크홀 관련 뉴스!\n*${item.title}*\n작성자: ${item.creator || '미상'}\n${item.summary}\n${item.link}${item.mediaContent ? '\n이미지: ' + item.mediaContent.url : ''}`;
      await sendSlackNotification(process.env.SLACK_WEBHOOK_URL, message);
      
      // Update notification status
      await dynamodb.update({
        TableName: process.env.DYNAMODB_TABLE,
        Key: { id: item.id },
        UpdateExpression: 'set notified = :notified',
        ExpressionAttributeValues: { ':notified': true }
      }).promise();
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `Processed ${relevantNews.length} news items`
      })
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing RSS feed',
        error: error.message
      })
    };
  }
};

