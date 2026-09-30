import ballerina/http;
import ballerina/jwt;
import ballerina/lang.array;
import ballerina/test;

const string TEST_ISSUER = "test-gateway";
const string TEST_PRIVATE_KEY_FILE = "tests/resources/test_private_key.pem";
const string OTHER_PRIVATE_KEY_FILE = "tests/resources/other_private_key.pem";

final http:Client greetingClient = check new ("http://localhost:9090");

isolated function mintAssertion(string keyFile, string callerSubject, string callerScope) returns string|error {
    jwt:IssuerConfig issuerConfig = {
        issuer: TEST_ISSUER,
        username: callerSubject,
        expTime: 300,
        customClaims: {"scope": callerScope, "ouHandle": "test-org"},
        signatureConfig: {
            algorithm: jwt:RS256,
            config: {keyFile: keyFile}
        }
    };
    return jwt:issue(issuerConfig);
}

isolated function base64UrlDecode(string urlSegment) returns byte[]|error {
    string withPlus = re `-`.replaceAll(urlSegment, "+");
    string withSlash = re `_`.replaceAll(withPlus, "/");
    int padLength = (4 - withSlash.length() % 4) % 4;
    string paddedSegment = withSlash;
    foreach int i in 0 ..< padLength {
        paddedSegment += "=";
    }
    return array:fromBase64(paddedSegment);
}

isolated function base64UrlEncode(byte[] rawBytes) returns string {
    string plainBase64 = rawBytes.toBase64();
    string noPlus = re `\+`.replaceAll(plainBase64, "-");
    string noSlash = re `/`.replaceAll(noPlus, "_");
    return re `=+$`.replaceAll(noSlash, "");
}

// Decodes the payload segment, edits a claim, re-encodes it and reassembles the
// token with the ORIGINAL signature — which no longer matches. Simulates a
// caller editing their own assertion after the gateway signed it.
isolated function tamperPayload(string signedToken) returns string|error {
    string[] tokenParts = re `\.`.split(signedToken);
    if tokenParts.length() != 3 {
        return error("not a JWT");
    }
    byte[] payloadBytes = check base64UrlDecode(tokenParts[1]);
    string payloadText = check string:fromBytes(payloadBytes);
    json payloadJson = check payloadText.fromJsonString();
    map<json> claimsMap = check payloadJson.ensureType();
    claimsMap["scope"] = "greeting:read admin:all-access";
    string tamperedPayload = claimsMap.toJsonString();
    string tamperedSegment = base64UrlEncode(tamperedPayload.toBytes());
    return tokenParts[0] + "." + tamperedSegment + "." + tokenParts[2];
}

@test:Config {}
function testValidAssertionIsAccepted() returns error? {
    string assertionToken = check mintAssertion(TEST_PRIVATE_KEY_FILE, "caller-1", "greeting:read");
    Greeting greetingResponse = check greetingClient->get("/greeting", {"x-jwt-assertion": assertionToken});
    test:assertEquals(greetingResponse.message, "Hello, world!");
}

@test:Config {}
function testGreetingIsIdenticalAcrossCallers() returns error? {
    string tokenForSam = check mintAssertion(TEST_PRIVATE_KEY_FILE, "caller-sam", "greeting:read");
    string tokenForJordan = check mintAssertion(TEST_PRIVATE_KEY_FILE, "caller-jordan", "greeting:read");
    Greeting samResponse = check greetingClient->get("/greeting", {"x-jwt-assertion": tokenForSam});
    Greeting jordanResponse = check greetingClient->get("/greeting", {"x-jwt-assertion": tokenForJordan});
    test:assertEquals(samResponse.message, jordanResponse.message);
}

@test:Config {}
function testAssertionSignedByAnotherKeyIsUnauthorized() returns error? {
    string assertionToken = check mintAssertion(OTHER_PRIVATE_KEY_FILE, "caller-1", "greeting:read");
    http:Response greetingResponse = check greetingClient->get("/greeting", {"x-jwt-assertion": assertionToken});
    test:assertEquals(greetingResponse.statusCode, 401);
}

@test:Config {}
function testTamperedPayloadIsUnauthorized() returns error? {
    string assertionToken = check mintAssertion(TEST_PRIVATE_KEY_FILE, "caller-1", "greeting:read");
    string tamperedToken = check tamperPayload(assertionToken);
    http:Response greetingResponse = check greetingClient->get("/greeting", {"x-jwt-assertion": tamperedToken});
    test:assertEquals(greetingResponse.statusCode, 401);
}

@test:Config {}
function testMissingAssertionIsUnauthorized() returns error? {
    http:Response greetingResponse = check greetingClient->get("/greeting");
    test:assertEquals(greetingResponse.statusCode, 401);
}
