/**
 * Spreader: Container Terminal Operating System
 * Unit Test Suite for TypeScript Port Community System Client
 */

import { PortCommunityClient } from "../client.js";

function assert(condition: boolean, msg: string = "Assertion failed"): void {
  if (!condition) {
    throw new Error(msg);
  }
}

function strictEqual<T>(actual: T, expected: T, msg?: string): void {
  if (actual !== expected) {
    throw new Error(msg || `Expected ${JSON.stringify(expected)} but got ${JSON.stringify(actual)}`);
  }
}

async function runTests(): Promise<void> {
  console.log("[TS TEST] Running Port Community System BAPLIE Client test suite...");

  const client = new PortCommunityClient();

  // Test 1: Empty payload validation
  const emptyRes = client.validateBaplie("");
  strictEqual(emptyRes.valid, false);
  assert(emptyRes.errors.length > 0, "Expected validation errors for empty input");

  // Test 2: Incomplete segments validation
  const incomplete = "UNB+UNOA:2+S+R+261118:1200+1'UNH+1+BAPLIE:D:95B:UN:SMDG22'";
  const incRes = client.validateBaplie(incomplete);
  strictEqual(incRes.valid, false);
  assert(incRes.errors.some((e) => e.includes("BGM")), "Expected missing BGM error");
  assert(incRes.errors.some((e) => e.includes("UNT")), "Expected missing UNT error");

  // Test 3: Complete sample BAPLIE
  const sampleBaplie =
    "UNB+UNOA:2+SPREADER+PORTROTT+261118:1200+1001'\n" +
    "UNH+1+BAPLIE:D:95B:UN:SMDG22'\n" +
    "BGM+BAY+0124W+9'\n" +
    "TDT+20+0124W+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'\n" +
    "LOC+5+CNSHA:139:6'\n" +
    "EQD+CN+MSKU1234567+42G1:102:5++4'\n" +
    "LOC+147+0010282:139:125'\n" +
    "MEA+WT++KGM:24000'\n" +
    "LOC+11+NLRTM:139:6'\n" +
    "EQD+CN+MSKU2345678+45R1:102:5++4'\n" +
    "LOC+147+0010484:139:125'\n" +
    "MEA+WT++KGM:26000'\n" +
    "LOC+11+DEHAM:139:6'\n" +
    "TMP+2+N18:CEL'\n" +
    "EQD+CN+MSKU3456789+22G1:102:5++4'\n" +
    "LOC+147+0010686:139:125'\n" +
    "MEA+WT++KGM:18000'\n" +
    "LOC+11+NLRTM:139:6'\n" +
    "DGS+IMD+3+1993'\n" +
    "UNT+19+1'\n" +
    "UNZ+1+1001'";

  const validRes = client.validateBaplie(sampleBaplie);
  strictEqual(validRes.valid, true);
  strictEqual(validRes.errors.length, 0);

  // Test 4: Parse Summary
  const summary = client.parseSummary(sampleBaplie);
  strictEqual(summary.voyageNumber, "0124W");
  strictEqual(summary.pol, "CNSHA");
  strictEqual(summary.containerCount, 3);
  strictEqual(summary.totalWeightTonnes, 68.0);
  strictEqual(summary.reeferCount, 1);
  strictEqual(summary.hazmatCount, 1);

  // Test 5: Transmit and Fetch round-trip
  const sendRes = await client.sendBaplie("0124W", sampleBaplie);
  strictEqual(sendRes.success, true);
  strictEqual(sendRes.statusCode, 200);

  const fetched = await client.fetchBaplie("0124W");
  strictEqual(fetched, sampleBaplie);

  console.log("[TS TEST] All TypeScript client tests passed successfully!");
}

runTests().catch((err) => {
  console.error(err);
  throw err;
});
