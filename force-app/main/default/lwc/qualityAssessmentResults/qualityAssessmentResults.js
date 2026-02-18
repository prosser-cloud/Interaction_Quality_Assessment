import { LightningElement, api, wire } from 'lwc';
import getQualityAssessmentResults from '@salesforce/apex/QualityAssessmentResultsController.getQualityAssessmentResults';

export default class QualityAssessmentResults extends LightningElement {
    @api recordId;
    
    assessmentData;
    error;
    isLoading = true;

    @wire(getQualityAssessmentResults, { recordId: '$recordId' })
    wiredAssessmentResults({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.assessmentData = this.processAssessmentData(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.assessmentData = undefined;
            console.error('Error loading assessment results:', error);
        }
    }

    processAssessmentData(data) {
        // Create new objects with computed properties
        return {
            ...data,
            sections: data.sections ? data.sections.map((section, index) => ({
                ...section,
                sectionScoreFormatted: this.getSectionScoreFormatted(section.sectionScore),
                sectionScoreClass: this.getSectionScoreClass(section.sectionScore),
                isExpanded: index === 0, // First section expanded by default
                sectionId: `section-${index}`,
                expandIcon: index === 0 ? 'utility:chevrondown' : 'utility:chevronright',
                questions: section.questions ? section.questions.map(question => ({
                    ...question,
                    questionScoreFormatted: this.getQuestionScoreFormatted(question.score),
                    questionScoreClass: this.getQuestionScoreClass(question),
                    questionTypeIcon: this.getQuestionTypeIcon(question.questionType),
                    passFailText: (question.passFailQuestion && question.score != null) ? 
                        (question.score >= 5 ? ' (Pass)' : ' (Fail)') : '',
                    showPassFail: question.passFailQuestion && question.score != null
                })) : []
            })) : []
        };
    }

    handleSectionToggle(event) {
        const sectionId = event.currentTarget.dataset.sectionId;
        
        // Create a new assessmentData object with updated section states
        this.assessmentData = {
            ...this.assessmentData,
            sections: this.assessmentData.sections.map(section => {
                const newIsExpanded = section.sectionId === sectionId ? !section.isExpanded : section.isExpanded;
                return {
                    ...section,
                    isExpanded: newIsExpanded,
                    expandIcon: newIsExpanded ? 'utility:chevrondown' : 'utility:chevronright'
                };
            })
        };
    }

    getExpandIcon(isExpanded) {
        return isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get hasData() {
        return this.assessmentData && this.assessmentData.sections && this.assessmentData.sections.length > 0;
    }

    get overallScoreFormatted() {
        return this.assessmentData?.overallScore ? Math.round(this.assessmentData.overallScore * 10) / 10 : 0;
    }

    get overallScoreClass() {
        const score = this.assessmentData?.overallScore || 0;
        if (score >= 8) return 'score-excellent';
        if (score >= 6) return 'score-good';
        if (score >= 4) return 'score-fair';
        return 'score-poor';
    }

    getSectionScoreFormatted(sectionScore) {
        return sectionScore ? Math.round(sectionScore * 10) / 10 : 0;
    }

    getSectionScoreClass(sectionScore) {
        const score = sectionScore || 0;
        if (score >= 8) return 'score-excellent';
        if (score >= 6) return 'score-good';
        if (score >= 4) return 'score-fair';
        return 'score-poor';
    }

    getQuestionScoreFormatted(questionScore) {
        return questionScore ? Math.round(questionScore * 10) / 10 : '-';
    }

    getQuestionScoreClass(question) {
        if (!question.score) return 'score-none';
        
        const score = question.score;
        if (question.passFailQuestion) {
            return score >= 5 ? 'score-pass' : 'score-fail';
        }
        
        if (score >= 8) return 'score-excellent';
        if (score >= 6) return 'score-good';
        if (score >= 4) return 'score-fair';
        return 'score-poor';
    }

    getQuestionTypeIcon(questionType) {
        switch(questionType) {
            case 'Scale': return 'utility:slider';
            case 'Pass/Fail': return 'utility:check';
            case 'Multiple Choice': return 'utility:radio_button';
            default: return 'utility:question';
        }
    }
}