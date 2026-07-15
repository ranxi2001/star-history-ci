import axios from "axios";
import api from "./vendor/shared/common/api";

let starCount = 2;
let requests = 0;

axios.defaults.adapter = async (config) => {
  requests += 1;
  const url = String(config.url);
  let data: unknown;

  if (url.includes("/stargazers")) {
    data = [];
  } else if (url.endsWith("/repos/fixture/example")) {
    data = { stargazers_count: starCount };
  } else {
    throw new Error(`Unexpected fixture request: ${url}`);
  }

  return {
    config,
    data,
    headers: {},
    status: 200,
    statusText: "OK",
  };
};

let restricted = false;
try {
  await api.getRepoStarRecords("fixture/example", "fixture-token", 16);
} catch (error: any) {
  restricted =
    error?.response?.status === 403 &&
    /admin or collaborator/.test(String(error?.response?.data?.message));
}
if (!restricted) throw new Error("Restricted empty stargazer response was not rejected");
if (requests !== 2) throw new Error(`Expected 2 restricted requests, got ${requests}`);

starCount = 0;
requests = 0;
let emptyRepository = false;
try {
  await api.getRepoStarRecords("fixture/example", "fixture-token", 16);
} catch (error: any) {
  emptyRepository = error?.status === 200 && Array.isArray(error?.data) && error.data.length === 0;
}
if (!emptyRepository) throw new Error("A repository with zero stars was not preserved as empty");
if (requests !== 2) throw new Error(`Expected 2 zero-star requests, got ${requests}`);

process.stdout.write("stargazer access tests passed\n");
