/**
 * Dyme Eat: The Legacy Engine - Cloud Functions (v2 SDK)
 *
 * This file contains the backend logic for aggregating reviews, awarding Influence Points (IP),
 * and managing other server-side tasks for the application, updated to use the Firebase Functions v2 SDK.
 */

// v2 Imports
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

// Legacy v1 import for functions.https.onCall
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * ==========================================================================================
 * TASTE DIAL & REVIEW FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered whenever a new review is written. It performs three main actions:
 * 1. Awards +25 IP to the author of the review.
 * 2. Triggers the aggregation of taste data for the associated restaurant.
 * 3. Checks if the user has met the criteria for the Revelation Event.
 */

export const onreviewcreated = onDocumentCreated("reviews/{reviewId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the review event.");
        return;
    }
    const reviewData = snap.data();
    const { authorId, restaurantId } = reviewData;

    if (!authorId || !restaurantId) {
        logger.error("Review is missing authorId or restaurantId.");
        return;
    }

    const userRef = db.collection("users").doc(authorId);
    await userRef.update({
      influencePoints: admin.firestore.FieldValue.increment(25),
    });
    logger.log(`Awarded +25 IP to user ${authorId} for new review.`);

    await recalculateTasteSignature(restaurantId);
    await checkForRevelationEvent(authorId);
});

async function recalculateTasteSignature(restaurantId: string) {
    const restaurantRef = db.collection("restaurants").doc(restaurantId);
    const reviewsSnapshot = await db.collection("reviews").where("restaurantId", "==", restaurantId).get();

    if (reviewsSnapshot.empty) {
        logger.log(`No reviews for restaurant ${restaurantId}. Resetting signature.`);
        await restaurantRef.update({ overallTasteSignature: {} });
        return;
    }

    const signature: { [key: string]: number } = {};
    const counts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const reviewData = doc.data();
        const tasteDialData = reviewData.tasteDialData as { [key: string]: number };
        if (tasteDialData) {
            for (const key in tasteDialData) {
                signature[key] = (signature[key] || 0) + tasteDialData[key];
                counts[key] = (counts[key] || 0) + 1;
            }
        }
    });

    const newTasteSignature: { [key: string]: number } = {};
    for (const key in signature) {
        newTasteSignature[key] = signature[key] / counts[key];
    }
    newTasteSignature._reviewCount = reviewsSnapshot.size;

    await restaurantRef.update({ overallTasteSignature: newTasteSignature,reviewCount: reviewsSnapshot.size, });
    logger.log(`Updated taste signature for restaurant ${restaurantId}`);
}

/**
 * ==========================================================================================
 * ONBOARDING & MBTI FUNCTIONS
 * ==========================================================================================
 */
/**
 * Calculates a user's Foodie Personality based on their quiz answers
 * and saves their preferences and allergies.
 */
export const processOnboardingQuiz = onCall(async (request) => {
    const uid = request.auth?.uid;
    const { answers, allergies, preferences } = request.data;

    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");
    if (!answers || !allergies || !preferences) {
        throw new HttpsError("invalid-argument", "Quiz data is incomplete.");
    }

    // --- Simple MBTI Calculation Logic (Example) ---
    // This logic should be expanded based on your specific quiz questions.
    let personality = "";
    // 1. Spontaneous vs. Planner (S/P)
    personality += answers.q1 === "try-it" ? "S" : "P"; 
    // 2. Traditional vs. Modern (T/M)
    personality += answers.q2 === "rendang" ? "T" : "M";
    // 3. Adventurous vs. Comfort (A/C)
    personality += answers.q3 === "long-queue" ? "A" : "C";
    // 4. Savory vs. Sweet (V/W)
    personality += answers.q4 === "mamak" ? "V" : "W";
    
    // --- Update the User Document in Firestore ---
    await db.collection("users").doc(uid).update({
        foodiePersonality: personality,
        allergies: allergies, // e.g., ["Seafood", "Nuts"]
        preferences: preferences, // e.g., ["Halal", "Spicy"]
        foodieCrestRevealed: true, // Mark quiz as complete
    });

    return { success: true, personality: personality };
});

/**
 * ==========================================================================================
 * PERSONALIZED RECOMMENDATION FUNCTIONS
 * ==========================================================================================
 */

/**
 * Gets personalized restaurant recommendations based on a user's Foodie MBTI.
 */
export const getMbtiRecommendations = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");

    const userDoc = await db.collection("users").doc(uid).get();
    const foodiePersonality = userDoc.data()?.foodiePersonality;

    if (!foodiePersonality) {
        throw new HttpsError("not-found", "User has no Foodie Personality yet.");
    }

    // --- Map MBTI to relevant tags (Malaysian Context) ---
    const tagMap: { [key: string]: string[] } = {
        "CAMK": ["lepak", "yumcha"], // Raja Lepak
        "RAKK": ["pedas-giler", "adventurous"], // Harimau Sambal
        "RAMS": ["dessert", "authentic-taste"], // Sang Kancil Cendol
        "CAMS": ["comfort-food", "rasa-asli"], // Pahlawan Pagi
        // ... (add mappings for all 16 personalities)
    };

    const relevantTags = tagMap[foodiePersonality] || [];
    if (relevantTags.length === 0) {
        return { recommendations: [] }; // No tags for this personality, return empty
    }

    // --- Find restaurants that have any of the relevant tags ---
    const restaurantsSnapshot = await db.collection("restaurants")
        .where("tags", "array-contains-any", relevantTags)
        .limit(10)
        .get();
        
    const recommendations = restaurantsSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            name: data.name,
            address: data.address,
            imageUrls: data.imageUrls || [],
        };
    });

    return { recommendations: recommendations };
});



/**
 * ==========================================================================================
 * PATHFINDER TIP FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered when a pathfinderTip document is updated (e.g., upvoted).
 * Checks if a tip has reached the verification threshold and awards IP if it has.
 */
export const onpathfindertipupdate = onDocumentUpdated("pathfinderTips/{tipId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the tip update event.");
        return;
    }
    const newData = snap.after.data();
    const oldData = snap.before.data();
    
    if (newData.upvotes === oldData.upvotes || newData.isVerified) {
        return;
    }

    const VERIFICATION_THRESHOLD = 3;
    if (newData.upvotes >= VERIFICATION_THRESHOLD) {
        const tipId = snap.after.id;
        const authorId = newData.authorId;
        if (!authorId) {
            logger.error(`Tip ${tipId} has no authorId.`);
            return;
        }
        await db.collection("pathfinderTips").doc(tipId).update({ isVerified: true });
        await db.collection("users").doc(authorId).update({
            influencePoints: admin.firestore.FieldValue.increment(15),
        });
        logger.log(`Tip ${tipId} verified. Awarded +15 IP to user ${authorId}.`);
    }
});


/**
 * ==========================================================================================
 * FOODIE PERSONALITY & REVELATION EVENT (NEW)
 * ==========================================================================================
 */

const REVELATION_THRESHOLD = 15; // Number of reviews needed to trigger the event

/**
 * Checks if a user has met the conditions for the Foodie Personality Revelation Event.
 * @param {string} userId The ID of the user to check.
 */
async function checkForRevelationEvent(userId: string) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  // Stop if the user doesn't exist or their crest has already been revealed.
  if (!userData || userData.foodieCrestRevealed) {
    return;
  }

  // Count the number of reviews the user has submitted.
  const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", userId).get();
    const reviewCount = reviewsSnapshot.size;
    logger.log(`User ${userId} has ${reviewCount} reviews.`);

    if (reviewCount >= REVELATION_THRESHOLD) {
        logger.log(`User ${userId} met revelation threshold. Analyzing...`);
        await analyzeAndAssignFoodiePersonality(userId, reviewsSnapshot);
    }
}

/**
 * Analyzes a user's review history to determine their 4-letter Foodie Personality,
 * awards them IP, and sets the `foodieCrestRevealed` flag.
 * @param {string} userId The user to analyze.
 * @param {FirebaseFirestore.QuerySnapshot} reviewsSnapshot The user's reviews.
 */
async function analyzeAndAssignFoodiePersonality(userId: string, reviewsSnapshot: FirebaseFirestore.QuerySnapshot) {
    const totals: { [key: string]: number } = {};
    const counts: { [key: string]: number } = {};

    reviewsSnapshot.forEach((doc) => {
        const tasteData = doc.data().tasteDialData as { [key: string]: number } || {};
        for (const key in tasteData) {
            totals[key] = (totals[key] || 0) + tasteData[key];
            counts[key] = (counts[key] || 0) + 1;
        }
    });

    const averages: { [key: string]: number } = {};
    for (const key in totals) {
        averages[key] = totals[key] / counts[key];
    }

    let personality = "";
    personality += (averages["Richness"] || 0) > (averages["Spiciness"] || 0) ? "R" : "S";
    const overallAverage = Object.values(averages).reduce((sum, val) => sum + val, 0) / (Object.keys(averages).length || 1);
    personality += overallAverage > 3.5 ? "I" : "M";
    personality += (averages["Sweetness"] || 0) > 3.0 ? "S" : "V";
    const allValues = reviewsSnapshot.docs.flatMap((doc) => Object.values(doc.data().tasteDialData || {}) as number[]);
    const variance = getVariance(allValues);
    personality += variance > 2.0 ? "B" : "N";

    await db.collection("users").doc(userId).update({
        foodiePersonality: personality,
        foodieCrestRevealed: true,
        influencePoints: admin.firestore.FieldValue.increment(500),
    });
    logger.log(`Revelation for user ${userId}! Personality: ${personality}. Awarded +500 IP.`);
}

function getVariance(numbers: number[]): number {
    if (numbers.length < 2) return 0;
    const mean = numbers.reduce((a, b) => a + b, 0) / numbers.length;
    return numbers.map((v) => (v - mean) ** 2).reduce((a, b) => a + b, 0) / numbers.length;
}  


/**
 * ==========================================================================================
 * RESTAURANT SUBMISSION FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * Triggered when a new restaurant suggestion is created.
 * This function currently serves as a placeholder for logging. The IP award
 * will happen when an admin approves the submission.
 */
export const onrestaurantsuggestioncreated = onDocumentCreated("submittedRestaurants/{submissionId}", (event) => {
    const submissionData = event.data?.data();
    if (submissionData) {
        logger.log("New restaurant suggestion received:", submissionData.name);
    }
});

export const onrestaurantsuggestionupdate = onDocumentUpdated("submittedRestaurants/{submissionId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();

    if (newData.status === "approved" && oldData.status !== "approved") {
        const { name, address, location, city, state, submittedBy, cuisineTags } = newData;
        if (!submittedBy) {
            logger.error("Approved submission is missing 'submittedBy' UID.");
            return;
        }
        await db.collection("restaurants").add({
            name, address, location, city: city || "", state: state || "",
            cuisineTags: cuisineTags || [], overallTasteSignature: {},
            createdBy: submittedBy, createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await db.collection("users").doc(submittedBy).update({
            influencePoints: admin.firestore.FieldValue.increment(100),
        });
        logger.log(`Approved restaurant '${name}'. Awarded +100 IP to user ${submittedBy}.`);
    }
});


// ==========================================================================================
// GROUP MODULE & STORY FUNCTIONS
// ==========================================================================================
/**
 * A helper function to recalculate a group's taste signature.
 * This is the core of the group AI.
 */
async function recalculateGroupTasteSignature(groupId: string) {
    const groupDoc = await db.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) {
        logger.error(`Group ${groupId} not found for recalculation.`);
        return;
    }
    const members = groupDoc.data()!.members as string[];
    if (members.length === 0) {
        await db.collection("groups").doc(groupId).update({ tasteSignature: {} });
        return; // No members, so clear the signature
    }

    // 1. Fetch all reviews from all members of the group
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "in", members).get();
    if (reviewsSnapshot.empty) {
        await db.collection("groups").doc(groupId).update({ tasteSignature: {} });
        return; // No reviews, so clear the signature
    }

    // 2. Aggregate all taste data
    const aggregatedTaste: { [key: string]: { total: number, count: number } } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            for (const [key, value] of Object.entries(review.tasteDialData as { [key: string]: number })) {
                if (!aggregatedTaste[key]) aggregatedTaste[key] = { total: 0, count: 0 };
                aggregatedTaste[key].total += value;
                aggregatedTaste[key].count += 1;
            }
        }
    });

    // 3. Calculate averages and save to the group document
    const newTasteSignature: { [key: string]: number } = {};
    for (const [key, { total, count }] of Object.entries(aggregatedTaste)) {
        newTasteSignature[key] = total / count;
    }
    
    await db.collection("groups").doc(groupId).update({ tasteSignature: newTasteSignature });
    logger.log(`Successfully updated taste signature for group ${groupId}.`);
}


/**
 * TRIGGER: When a user submits a review, find all groups they belong to and
 * trigger a recalculation of each group's taste signature.
 */
export const onReviewCreatedForGroupUpdate = onDocumentCreated("reviews/{reviewId}", async (event) => {
    const reviewData = event.data?.data();
    if (!reviewData?.authorId) return;

    const userGroupsSnapshot = await db.collection("groups").where("members", "array-contains", reviewData.authorId).get();
    
    const recalcPromises = userGroupsSnapshot.docs.map(doc => recalculateGroupTasteSignature(doc.id));
    await Promise.all(recalcPromises);
});


/**
 * TRIGGER: Triggered whenever a group's member list is updated.
 * This ensures the Group Taste Compass is always up-to-date.
 */
export const onGroupUpdate = onDocumentUpdated("groups/{groupId}", async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Check if the members array has actually changed to avoid unnecessary recalculations.
    if (JSON.stringify(beforeData?.members) !== JSON.stringify(afterData?.members)) {
        logger.log(`Group ${event.params.groupId} members changed. Recalculating taste signature.`);
        await recalculateGroupTasteSignature(event.params.groupId);
    }
});


/**
 * CALLABLE: Creates a new group.
 */
export const creategroup = onCall(async (request) => {
    const uid = request.auth?.uid;
    const groupName = request.data.name;

    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");
    if (!groupName || typeof groupName !== "string" || groupName.length > 50) {
        throw new HttpsError("invalid-argument", "Group name must be valid.");
    }

    const groupRef = await db.collection("groups").add({
        name: groupName, createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        members: [uid], tasteSignature: {}, allergies: {},
    });
    return { groupId: groupRef.id };
});

/**
 * CALLABLE: Adds a new member to a group.
 */
export const addMemberToGroup = onCall(async (request) => {
    const uid = request.auth?.uid;
    const { groupId, newUserEmail } = request.data;
    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");
    if (!groupId || !newUserEmail) throw new HttpsError("invalid-argument", "Group ID and email are required.");
    
    const groupRef = db.collection("groups").doc(groupId);
    const groupDoc = await groupRef.get();
    if (!groupDoc.exists) throw new HttpsError("not-found", "Group not found.");
    
    const groupData = groupDoc.data()!;
    if (!groupData.members.includes(uid)) throw new HttpsError("permission-denied", "You are not a member of this group.");
    
    const newUserQuery = await db.collection("users").where("email", "==", newUserEmail).limit(1).get();
    if (newUserQuery.empty) throw new HttpsError("not-found", `User with email ${newUserEmail} not found.`);
    
    const newMemberId = newUserQuery.docs[0].id;
    await groupRef.update({ members: admin.firestore.FieldValue.arrayUnion(newMemberId) });
    return { success: true, message: "Member added successfully." };
});

/**
 * CALLABLE: Gets a ranked list of the Top 5 restaurant recommendations for the group.
 */
export const getGroupRecommendations = onCall(async (request) => {
    const { groupId } = request.data;
    if (!groupId) throw new HttpsError("invalid-argument", "Group ID is required.");

    const groupDoc = await db.collection("groups").doc(groupId).get();
    const groupData = groupDoc.data();

    if (!groupData?.tasteSignature) {
        throw new HttpsError("not-found", "Group taste signature has not been calculated yet.");
    }
    
    const tasteSignature = groupData.tasteSignature as { [key: string]: number };
    const topFlavor = Object.keys(tasteSignature).reduce((a, b) => tasteSignature[a] > tasteSignature[b] ? a : b, "");

    if (!topFlavor) throw new HttpsError("not-found", "Could not determine a top flavor for the group.");

    const restaurantsSnapshot = await db.collection("restaurants")
        .orderBy(`overallTasteSignature.${topFlavor}`, "desc")
        .limit(5)
        .get();

    if (restaurantsSnapshot.empty) {
        throw new HttpsError("not-found", `No restaurants found that match the group's top flavor: ${topFlavor}.`);
    }
    
    const recommendations = restaurantsSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            name: data.name,
            address: data.address,
            imageUrls: data.imageUrls || [],
        };
    });

    return { recommendations: recommendations };
});

/**
 * CALLABLE: Handles a direct "group rating" for a restaurant.
 */
export const rateRestaurantForGroup = onCall(async (request) => {
    const uid = request.auth?.uid;
    const { groupId, restaurantId, rating } = request.data;
    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");
    if (!groupId || !restaurantId || !rating) throw new HttpsError("invalid-argument", "All fields are required.");

    logger.log(`Received rating of ${rating} for restaurant ${restaurantId} from user ${uid} for group ${groupId}.`);
    await recalculateGroupTasteSignature(groupId);
    
    return { success: true, message: "Rating submitted and group preferences updated." };
});

export const onstorycreated = onDocumentCreated("stories/{storyId}", (event) => {
    const storyData = event.data?.data();
    if (storyData) {
        logger.log(`New story submitted for restaurant ${storyData.restaurantId} by user ${storyData.authorId}.`);
    }
});

/**
 * ==========================================================================================
 * FOODIE CARD FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * A callable function that generates the data payload for a user's Foodie Card.
 * This data can be used by the client to generate a QR code and display the card.
 */
export const generateFoodieCardData = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new HttpsError("not-found", "User not found.");
    }
    const userData = userDoc.data()!;

    // --- Analyze reviews to find top flavors ---
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", uid).get();
    
    const flavorCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            Object.keys(review.tasteDialData).forEach((key) => {
                flavorCounts[key] = (flavorCounts[key] || 0) + 1;
            });
        }
    });
    // Sort by frequency and get the top 3
    const topFlavors = Object.entries(flavorCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([key]) => key);

    // --- Construct the data payload ---
    const cardData = {
        userId: uid,
        name: userData.displayName || "N/A",
        crest: userData.foodiePersonality || "Not Revealed",
        ip: userData.influencePoints || 0,
        topFlavors: topFlavors,
    };

    // The client will stringify this JSON for the QR code
    return cardData;
});

/**
 * ==========================================================================================
 * WALLET INTEGRATION (PKPASS) FUNCTIONS
 * ==========================================================================================
 */

/**
 * Prepares the data payload required to generate a .pkpass file for Apple Wallet.
 *
 * NOTE: This function *prepares* the data. A separate, dedicated service with access
 * to Apple's signing certificates is required to perform the actual .pkpass
 * file creation and signing. This function returns the JSON that service would need.
 */
export const generatePkpassData = onCall(async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
        throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new HttpsError("not-found", "User data not found.");
    }
    const userData = userDoc.data()!;

    // This data structure mirrors the fields you would define in a pass.json file.
    const passJson = {
        formatVersion: 1,
        passTypeIdentifier: "pass.com.dyme.eat.foodie-card", // Your Pass Type ID from Apple
        serialNumber: `DYME-${uid.substring(0, 10)}`,
        teamIdentifier: "YOUR_TEAM_ID", // Your Apple Developer Team ID
        organizationName: "Dyme Eat",
        description: "Dyme Eat Foodie Card",
        logoText: "Dyme Eat",
        foregroundColor: "rgb(255, 255, 255)",
        backgroundColor: "rgb(30, 30, 30)",
        labelColor: "rgb(180, 180, 180)",
        storeCard: {
            primaryFields: [
                {
                    key: "name",
                    label: "FOODIE",
                    value: userData.displayName || "N/A",
                },
            ],
            secondaryFields: [
                {
                    key: "crest",
                    label: "FOODIE CREST",
                    value: userData.foodiePersonality || "Not Revealed",
                },
            ],
            auxiliaryFields: [
                {
                    key: "ip",
                    label: "INFLUENCE",
                    value: `${userData.influencePoints || 0} IP`,
                },
            ],
            backFields: [
                {
                    key: "userId",
                    label: "User ID",
                    value: uid,
                },
                {
                    key: "info",
                    label: "About",
                    value: "This card represents your unique taste profile in the Dyme Eat ecosystem. Share it to connect with other foodies!",
                },
            ],
        },
        barcode: {
            message: JSON.stringify({ userId: uid }),
            format: "PKBarcodeFormatQR",
            messageEncoding: "iso-8859-1",
        },
    };

    // In a real implementation, you would send this `passJson` to your signing service.
    // Here, we return a success message and a placeholder for the download URL.
    return {
        success: true,
        message: "Pass data generated successfully.",
        // This URL would point to your signing service which returns the .pkpass file.
        downloadUrl: `https://your-pkpass-service.com/generate?data=${encodeURIComponent(JSON.stringify(passJson))}`,
    };
});




