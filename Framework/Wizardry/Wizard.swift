//
//  Wizard.swift
//  Wizardry
//
//  Created by Joshua Smith on 4/30/16.
//  Copyright © 2016 iJoshSmith. All rights reserved.
//

import Foundation

/// Transitions through a series of steps, enabling the user to perform a task by completing sub-tasks.
public final class Wizard {
    
    internal private(set) var currentStep: WizardStep?
    private let dataSource: WizardDataSource
    private weak var delegate: WizardDelegate?
    private var isTransitioning = false

    public init(dataSource: WizardDataSource, delegate: WizardDelegate) {
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    /// Transition to the first step. This should only be called once, to initialize the wizard when the UI is ready.
    public func goToInitialStep() {
        assertMainThread()
        
        guard currentStep == nil else {
            assertionFailure("Cannot go to the initial step more than once.")
            return
        }
        
        let initialStep = dataSource.initialWizardStep
        goTo(initialStep)
    }
    
    /// Transition to the next step, or, if on the last step, finish the wizard. This can be canceled by the current step.
    public func goToNextStep() {
        assertMainThread()
        
        guard let currentStep = currentStep else { return }
        
        if isTransitioning { return }
        isTransitioning = true
        currentStep.doWorkBeforeWizardGoesToNextStepWithCompletionHandler { [weak self] (shouldGoToNextStep: Bool) in
            assertMainThread()
            if shouldGoToNextStep {
                self?.goToStepAfter(currentStep)
            }
            self?.isTransitioning = false
        }
    }
    
    /// Transition to the previous step, or, if on the initial step, cancel the wizard. This can be canceled by the current step.
    public func goToPreviousStep() {
        assertMainThread()
        
        guard let currentStep = currentStep else { return }
        
        if isTransitioning { return }
        isTransitioning = true
        currentStep.doWorkBeforeWizardGoesToPreviousStepWithCompletionHandler { [weak self] (shouldGoToPreviousStep: Bool) in
            assertMainThread()
            if shouldGoToPreviousStep {
                self?.goToStepBefore(currentStep)
            }
            self?.isTransitioning = false
        }
    }
}



// MARK: - Transitioning between steps

private extension Wizard {
    
    func goTo(initialStep: WizardStep) {
        currentStep = initialStep
        delegate?.wizard(self, didGoToInitialWizardStep: initialStep)
    }
    
    func goToStepAfter(wizardStep: WizardStep) {
        currentStep = dataSource.wizardStepAfter(wizardStep)
        if let currentStep = currentStep {
            let placement = dataSource.placementOf(currentStep)
            delegate?.wizard(self, didGoToNextWizardStep: currentStep, placement: placement)
        }
        else {
            delegate?.wizardDidFinish(self)
        }
    }
    
    func goToStepBefore(wizardStep: WizardStep) {
        currentStep = dataSource.wizardStepBefore(wizardStep)
        if let currentStep = currentStep {
            let placement = dataSource.placementOf(currentStep)
            delegate?.wizard(self, didGoToPreviousWizardStep: currentStep, placement: placement)
        }
        else {
            delegate?.wizardDidCancel(self)
        }
    }
}

private func assertMainThread() {
    // A Wizard object is intimately tied to the user interface, which means it 
    // should only be access on the main thread, like all other UI objects.
    assert(NSThread.isMainThread(), "Wizard should only be used on the main thread.")
}
