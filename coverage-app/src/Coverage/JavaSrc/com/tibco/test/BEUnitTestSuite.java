package com.tibco.test;

import java.util.ArrayList;
import java.util.List;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import com.tibco.cep.kernel.model.knowledgebase.DuplicateExtIdException;
import com.tibco.cep.runtime.model.event.SimpleEvent;
import com.tibco.cep.runtime.model.event.impl.ObjectPayload;
import com.tibco.cep.runtime.model.element.Concept;
import com.tibco.cep.runtime.service.tester.beunit.BETestEngine;
import com.tibco.cep.runtime.service.tester.beunit.ExpectationType;
import com.tibco.cep.runtime.service.tester.beunit.Expecter;
import com.tibco.cep.runtime.service.tester.beunit.TestDataHelper;

/**
 * @description 
 */
public class BEUnitTestSuite {
	private static BETestEngine engine;
	private static TestDataHelper helper;
	private static Expecter expecter;

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		engine = new BETestEngine("target/coverage-1.0.0.ear", "/Users/shivkumarchelwa/Applications/BE5.5/be/5.5/bin/be-engine.tra",
				"coverage.cdd", "default", "inference-class", true);
		System.setProperty("tibco.clientVar.KAFKA_URL", "localhost:9092");

		// Start the test engine
		engine.start();
		
		// Create a helper to work with test data
		helper = new TestDataHelper(engine);
		
		// Create an Expecter object to test rule execution, modifications, assertions, etc.
		expecter = new Expecter(engine);
	}

	@AfterClass
	public static void tearDownAfterClass() throws Exception {
		try {
			engine.shutdown();
		} catch (Exception localException) {
		}
	}

	@Before
	public void setUp() throws Exception {
	}

	@After
	public void tearDown() throws Exception {
	}
	
	/**
	* Test whether one rule fired after another rule during rule execution, in order 
	* (use expectUnordered to test whether both rules fired in any order) 
	*/
	@Test
	public void testRuleOrder() throws Exception {
		engine.resetSession(); // (optional) reset the rule session, which will clear working memory, restart timers, and clear the data from any previous tests

		// TODO : Change test data path here to create concepts to be asserted from a test data file
		//List<Concept> concepts = helper.createConceptsFromTestData("/TestData/<test data file name>");
		//engine.assertConcepts(concepts, false);
		assertTestData();
		
		engine.executeRules();
		List<String> rules = new ArrayList<String>();
		rules.add("/Rules/sendResponse"); // TODO : Change the name to the first expected rule
		rules.add("/Rules/sendWaypointEvents"); // TODO : Change the name to a rule expected to fire after the previous rule
		expecter.expectOrdered(rules, ExpectationType.RULE_EXECTION);
	}
	
	/**
	* Test whether a particular Concept was modified by the engine during rule execution
	*/
	@Test
	public void testConceptUnmodified() throws Exception {
		engine.resetSession(); // (optional) reset the rule session, which will clear working memory, restart timers, and clear the data from any previous tests

		// TODO : Change test data path here to create concepts to be asserted from a test data file
		//List<Concept> concepts = helper.createConceptsFromTestData("/TestData/<test data file name>");
		//engine.assertConcepts(concepts, false);
		assertTestData();
		
		engine.executeRules();
		// TODO : Change the concept name to test whether the concept was modified during rule processing
		expecter.expectUnmodified("/Concepts/CoverageStatus");
	}
	
	/**
	* Test whether a particular Concept or Event is still in working memory
	*/
	@Test
	public void testWorkingMemory() throws Exception {
		engine.resetSession(); // (optional) reset the rule session, which will clear working memory, restart timers, and clear the data from any previous tests

		// TODO : Change test data path here to create concepts to be asserted from a test data file
		//List<Concept> concepts = helper.createConceptsFromTestData("/TestData/<test data file name>");
		//engine.assertConcepts(concepts, false);
		assertTestData();
		
		engine.executeRules();
		// TODO : Change the concept name to test whether the concept was modified during rule processing
		expecter.expectInWorkingMemory("/Concepts/CoverageStatus");
	}
	
	/**
	* Test whether a particular Rule has fired
	*/
	@Test
	public void testRuleFired() throws Exception {
		engine.resetSession(); // (optional) reset the rule session, which will clear working memory, restart timers, and clear the data from any previous tests

		// TODO : Change test data path here to create concepts to be asserted from a test data file
		//List<Concept> concepts = helper.createConceptsFromTestData("/TestData/<test data file name>");
		//engine.assertConcepts(concepts, false);
		assertTestData();
		engine.executeRules();
		expecter.expectRuleFired("/Rules/checkDisqualified"); // TODO : Change the name to a rule expected to fire
	}	
	
	private void assertTestData() throws Exception, DuplicateExtIdException {
		List<Concept> concepts = helper.createConceptsFromTestData("/TestData/CoverageStatus");
		engine.assertConcepts(concepts, false);
		
		List<SimpleEvent> eventList = helper.createEventsFromTestData("/TestData/CoverageRequest");
		for (SimpleEvent simpleEvent : eventList) {
			simpleEvent.setPayload(new ObjectPayload("{ \"resourceType\": \"EligibilityRequest\", \"ID\": \"1234\", \"patient\": {\"reference\": \"deceased\"},\"organization\": {\"reference\": \"P-000018\"},\"insurer\": {\"reference\": \"org2\"}, \"coverage\": {\"reference\": \"C-000005\"} }"));
		}
		engine.assertEvents(eventList, true);
	}
}