const { handler } = require('./index');
const AWS = require('aws-sdk');

jest.mock('aws-sdk');

describe('API Lambda', () => {
  let mockDynamoDb;

  beforeEach(() => {
    process.env.DYNAMODB_TABLE = 'test-table';
    
    mockDynamoDb = {
      scan: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({
          Items: [
            {
              id: '123',
              title: '테스트 싱크홀',
              location: '서울시 강남구',
              lat: 37.5,
              lng: 127.0
            }
          ]
        })
      }),
      update: jest.fn().mockReturnValue({
        promise: jest.fn().mockResolvedValue({
          Attributes: {
            id: '123',
            location: '서울시 강남구',
            lat: 37.5,
            lng: 127.0
          }
        })
      })
    };

    AWS.DynamoDB.DocumentClient.mockImplementation(() => mockDynamoDb);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('GET /sinkholes should return list of sinkholes', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/sinkholes'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toHaveLength(1);
    expect(mockDynamoDb.scan).toHaveBeenCalled();
  });

  test('PUT /sinkholes/{id} should update sinkhole location', async () => {
    const event = {
      httpMethod: 'PUT',
      path: '/sinkholes/123',
      body: JSON.stringify({
        location: '서울시 강남구',
        lat: 37.5,
        lng: 127.0
      })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(200);
    expect(mockDynamoDb.update).toHaveBeenCalled();
    expect(JSON.parse(response.body)).toHaveProperty('location', '서울시 강남구');
  });

  test('should handle unknown routes', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/unknown'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
  });

  test('should handle errors gracefully', async () => {
    mockDynamoDb.scan.mockReturnValue({
      promise: jest.fn().mockRejectedValue(new Error('DB Error'))
    });

    const event = {
      httpMethod: 'GET',
      path: '/sinkholes'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(500);
    expect(JSON.parse(response.body)).toHaveProperty('message', 'Internal Server Error');
  });
});