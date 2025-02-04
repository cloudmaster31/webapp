const request = require("supertest");
const app = require("../app");
const { sequelize,connectDatabase } = require("../database");

beforeAll(async () => {
  await connectDatabase();
});

afterAll(async () => {
  await sequelize.close();
});

describe("Health Check API", () => {
  test("GET /healthz should return 200", async () => {
    const res = await request(app).get("/healthz");
    expect(res.status).toBe(200);
  });

  test("Invalid POST method on /healthz should return 405", async () => {
    const res = await request(app).post("/healthz");
    expect(res.status).toBe(405);
  });
  test("Invalid PUT method on /healthz should return 405", async () => {
    const res = await request(app).put("/healthz");
    expect(res.status).toBe(405);
  });
  test("Invalid GET method on /healthz with body should return 400", async () => {
    const response = await request(app)
      .get("/healthz")
      .send({ key: "value" });
    expect(response.status).toBe(400);
  });
});
