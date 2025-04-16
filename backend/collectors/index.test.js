const { handler } = require('./index');
const axios = require('axios');
const AWS = require('aws-sdk');

jest.mock('axios');
jest.mock('aws-sdk');

describe('RSS Collector Lambda', () => {
  beforeEach(() => {
    process.env.DYNAMODB_TABLE = 'test-table';
    process.env.SLACK_WEBHOOK_URL = 'https://hooks.slack.com/test';
    process.env.RSS_FEED_URL = 'https://test.com/rss';
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('should process RSS feed and save relevant news', async () => {
    // Mock RSS feed response
    const mockRssResponse = {
      data: `<?xml version="1.0" encoding="UTF-8"?>
        <rss xmlns:content="http://purl.org/rss/1.0/modules/content/" 
             xmlns:dc="http://purl.org/dc/elements/1.1/" 
             xmlns:media="http://search.yahoo.com/mrss/" 
             xmlns:atom="http://www.w3.org/2005/Atom" 
             xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" 
             version="2.0">
          <channel>
            <title><![CDATA[연합뉴스 최신기사]]></title>
            <link>https://www.yna.co.kr/news</link>
            <description><![CDATA[연합뉴스 실시간 최신뉴스입니다]]></description>
            <language>ko-KR</language>
            <item>
              <title><![CDATA[서울 도심에 싱크홀 발생]]></title>
              <link>https://test.com/news/1</link>
              <guid isPermaLink="true">https://test.com/news/1</guid>
              <pubDate>Tue, 15 Nov 2023 09:00:00 GMT</pubDate>
              <dc:creator>테스트기자</dc:creator>
              <description><![CDATA[도로에 싱크홀이 발생하여...]]></description>
              <media:content url="https://test.com/image1.jpg" type="image/jpeg"/>
            </item>
          </channel>
        </rss>`
    };

    axios.get.mockResolvedValue(mockRssResponse);

    // Mock DynamoDB operations
    const mockDynamoDb = {
      put: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({})
      }),
      update: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({})
      })
    };

    AWS.DynamoDB.DocumentClient.mockImplementation(() => mockDynamoDb);

    // Execute handler
    const result = await handler({});

    // Verify results
    expect(result.statusCode).toBe(200);
    expect(axios.get).toHaveBeenCalledWith(process.env.RSS_FEED_URL);
    expect(mockDynamoDb.put).toHaveBeenCalled();
    expect(axios.post).toHaveBeenCalledWith(
      process.env.SLACK_WEBHOOK_URL,
      expect.any(Object)
    );
  });

  test('should handle errors gracefully', async () => {
    axios.get.mockRejectedValue(new Error('Network error'));

    const result = await handler({});

    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).message).toBe('Error processing RSS feed');
  });
});
